{ config, lib, pkgs, ... }:
let
    cfg = config.technet.clevis;
    tang = config.technet.tang;

    clevisPackage = config.boot.initrd.clevis.package;

    zfs = "${config.boot.zfs.package}/sbin/zfs";
    clevis = "${clevisPackage}/bin/clevis";
    systemd = config.boot.initrd.systemd.package;

    sssConfig = builtins.toJSON {
        t = 1;
        pins.tang = map (url: { inherit url; }) tang.urls;
    };

    jweFile = ds: "${cfg.stateDir}/${builtins.replaceStrings [ "/" ] [ "-" ] ds}.jwe";

    pools = lib.unique (map (ds: lib.head (lib.splitString "/" ds)) cfg.datasets);

    importServices = map (pool: "zfs-import-${pool}.service") pools;

    retryScript = ''
        set -u
        remaining="${lib.concatStringsSep " " cfg.datasets}"
        unlocked_any=false

        while [ -n "$remaining" ]; do
            still_locked=""
            for ds in $remaining; do
                status="$(${zfs} get -H -o value keystatus "$ds" 2>/dev/null || echo unavailable)"
                if [ "$status" = available ]; then
                    echo "clevis-retry: $ds already unlocked"
                    continue
                fi
                jwe="/etc/clevis/$ds.jwe"
                if [ -r "$jwe" ] && ${clevis} decrypt < "$jwe" | ${zfs} load-key -L prompt "$ds" 2>/dev/null; then
                    echo "clevis-retry: unlocked $ds"
                    unlocked_any=true
                    continue
                fi
                still_locked="$still_locked''${still_locked:+ }$ds"
            done
            remaining="$still_locked"
            [ -n "$remaining" ] || break
            sleep 5
        done

        if [ -z "$remaining" ]; then
            echo "clevis-retry: all clevis datasets unlocked"
        fi

        # The stock zfs-import services may already be sitting on a password prompt,
        # started before tang became reachable. They re-read keystatus on every start,
        # so restarting them now makes the prompt a no-op and cancels the outstanding
        # password request. Only worth doing if we actually unlocked something.
        if [ "$unlocked_any" = true ]; then
            for unit in ${lib.concatStringsSep " " importServices}; do
                state="$(${systemd}/bin/systemctl show -P ActiveState "$unit" 2>/dev/null || echo unknown)"
                case "$state" in
                    activating|active|failed)
                        echo "clevis-retry: restarting $unit (was $state)"
                        ${systemd}/bin/systemctl restart "$unit" || true
                        ;;
                    *)
                        echo "clevis-retry: $unit is $state, leaving it alone"
                        ;;
                esac
            done

            # Restarting the import services is not enough on its own: if they timed
            # out on the prompt first, zfs-import.target and the sysroot mounts have
            # already failed by dependency, and systemd does not retry a job that has
            # already failed. Start them explicitly so the boot can carry on.
            for unit in zfs-import.target initrd-fs.target; do
                state="$(${systemd}/bin/systemctl show -P ActiveState "$unit" 2>/dev/null || echo unknown)"
                if [ "$state" != active ]; then
                    echo "clevis-retry: starting $unit (was $state)"
                    ${systemd}/bin/systemctl start --no-block "$unit" || true
                fi
            done
        fi

        # Always succeed: Restart=on-failure must never turn this into a restart loop.
        exit 0
    '';

    rebindClevis = pkgs.writeShellApplication {
        name = "rebind-clevis";
        runtimeInputs = [
            clevisPackage
            pkgs.curl
            pkgs.coreutils
        ];
        text = ''
            set -euo pipefail

            PASSPHRASE_FILE="${config.sops.secrets.zfs_passphrase.path}"

            if [ "$(id -u)" -ne 0 ]; then
                echo "rebind-clevis: must run as root" >&2
                exit 1
            fi

            if [ ! -r "$PASSPHRASE_FILE" ]; then
                echo "rebind-clevis: cannot read $PASSPHRASE_FILE" >&2
                echo "rebind-clevis: check that zfs_passphrase exists in the host's sops file" >&2
                exit 1
            fi

            if [ -z "$(tr -d '\n' < "$PASSPHRASE_FILE")" ]; then
                echo "rebind-clevis: $PASSPHRASE_FILE is empty, refusing" >&2
                exit 1
            fi

            reachable=0
            for url in ${lib.concatStringsSep " " tang.urls}; do
                if curl -sf --max-time 5 "$url/adv" > /dev/null; then
                    echo "rebind-clevis: tang reachable at $url"
                    reachable=$((reachable + 1))
                else
                    echo "rebind-clevis: tang NOT reachable at $url" >&2
                fi
            done

            if [ "$reachable" -eq 0 ]; then
                echo "rebind-clevis: no tang server reachable, aborting" >&2
                exit 1
            fi

            if [ "$reachable" -ne ${toString (builtins.length tang.urls)} ]; then
                echo "rebind-clevis: WARNING - only $reachable of ${toString (builtins.length tang.urls)} tang addresses responded." >&2
                echo "rebind-clevis: unreachable addresses are still bound but unverified." >&2
            fi

            install -d -m 0700 -o root -g root "${cfg.stateDir}"

            expected="$(tr -d '\n' < "$PASSPHRASE_FILE")"

            ${lib.concatMapStringsSep "\n" (ds: ''
                tmp="$(mktemp)"
                trap 'rm -f "$tmp"' EXIT

                printf '%s' "$expected" | clevis encrypt sss '${sssConfig}' -y > "$tmp"

                if [ "$(clevis decrypt < "$tmp")" != "$expected" ]; then
                    echo "rebind-clevis: round-trip FAILED for ${ds}, refusing to write" >&2
                    exit 1
                fi

                install -m 0400 -o root -g root "$tmp" "${jweFile ds}"
                rm -f "$tmp"
                trap - EXIT
                echo "rebind-clevis: wrote ${jweFile ds} (${ds})"
            '') cfg.datasets}

            echo
            echo "rebind-clevis: all JWEs rebound and verified."
            echo "Apply them to the initrd with:"
            echo "  sudo nixos-rebuild boot --flake .#${config.networking.hostName}"
        '';
    };
in
{
    options.technet.clevis = {
        enable = lib.mkEnableOption "clevis/tang ZFS unlocking with rebind tooling";

        datasets = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
                "data-pool-${config.networking.hostName}/storage"
                "root-pool-${config.networking.hostName}/root"
            ];
            defaultText = lib.literalExpression ''
                [ "data-pool-\''${hostName}/storage" "root-pool-\''${hostName}/root" ]
            '';
            description = ''
                ZFS datasets unlocked via clevis at boot.

                The default is the standard TechNet layout laid down by
                3-filesystem/1-disko.nix (the root pool) plus the host's data pool.
                Override this on a host whose pools differ from that layout.
            '';
        };

        stateDir = lib.mkOption {
            type = lib.types.str;
            default = "/persistent/etc/clevis";
            description = ''
                Persistent directory holding the JWEs. These are read off the running
                filesystem at nixos-rebuild time and embedded into the initrd, so they
                never enter the Nix store. rebind-clevis writes here directly.
            '';
        };

        sopsFile = lib.mkOption {
            type = lib.types.path;
            description = "sops file holding zfs_passphrase for this host.";
        };

    };

    config = lib.mkIf cfg.enable {
        sops.secrets.zfs_passphrase = {
            sopsFile = cfg.sopsFile;
            mode = "0400";
        };

        environment.systemPackages = [ rebindClevis ];

        boot.initrd = {
            clevis = {
                enable = true;
                useTang = true;
                devices = lib.genAttrs cfg.datasets (ds: {
                    secretFile = jweFile ds;
                });
            };

            systemd.services.clevis-retry = {
                description = "Keep retrying clevis/tang unlock in the background until it succeeds";
                # Deliberately NOT a blocking oneshot and deliberately not ordered before
                # anything: the loop can run forever when tang is unreachable, so any
                # target that waits for it would stall the whole boot -- including the
                # initrd sshd, which is the only way in to fix such a machine remotely.
                wantedBy = [ "initrd.target" ];
                after = [ "systemd-modules-load.service" ];
                unitConfig = {
                    DefaultDependencies = "no";
                    ConditionPathExists = "/etc/clevis";
                };
                serviceConfig = {
                    Type = "simple";
                    Restart = "on-failure";
                    RestartSec = 15;
                };
                script = retryScript;
            };
        };
    };
}
