{ config, lib, pkgs, ... }:
let
    cfg = config.technet.clevis;
    tang = config.technet.tang;

    clevisPackage = config.boot.initrd.clevis.package;

    zfs = "${config.boot.zfs.package}/sbin/zfs";
    clevis = "${clevisPackage}/bin/clevis";

    sssConfig = builtins.toJSON {
        t = 1;
        pins.tang = map (url: { inherit url; }) tang.urls;
    };

    jweFile = ds: "${cfg.stateDir}/${builtins.replaceStrings [ "/" ] [ "-" ] ds}.jwe";

    retryScript = ''
        set -u
        remaining="${lib.concatStringsSep " " cfg.datasets}"
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
                    continue
                fi
                still_locked="$still_locked''${still_locked:+ }$ds"
            done
            remaining="$still_locked"
            [ -n "$remaining" ] || break
            sleep 15
        done
        echo "clevis-retry: all clevis datasets unlocked"
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
            description = "ZFS datasets unlocked via clevis at boot.";
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
                wantedBy = [ "sysinit.target" ];
                after = [ "systemd-modules-load.service" ];
                before = [ "zfs-import.target" ];
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
