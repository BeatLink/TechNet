# Clevis #############################################################################################################################################
#
# Unlocks this host's ZFS datasets at boot against the tang servers, and the tool that rebinds the JWEs when those keys change.
#

{ config, lib, pkgs, ... }:
let
    tangCfg = config.technet.tang;
    clevisCfg = config.technet.clevis;

    # Helpers ----------------------------------------------------------------------------------------------------------------------------------------
    clevisPackage = config.boot.initrd.clevis.package;
    zfs = "${config.boot.zfs.package}/sbin/zfs";
    clevis = "${clevisPackage}/bin/clevis";
    systemd = config.boot.initrd.systemd.package;
    plymouth = "${config.boot.plymouth.package}/bin/plymouth";

    sssConfig = builtins.toJSON {
        t = 1;
        pins.tang = map (url: { inherit url; }) tangCfg.urls;
    };

    jweFile = ds: "${clevisCfg.stateDir}/${builtins.replaceStrings [ "/" ] [ "-" ] ds}.jwe";

    pools = lib.unique (map (ds: lib.head (lib.splitString "/" ds)) clevisCfg.datasets);

    importServices = map (pool: "zfs-import-${pool}.service") pools;

    # Retry Loop -------------------------------------------------------------------------------------------------------------------------------------
    # Retries every still-locked dataset until they all open, then nudges the import units that were left waiting on a prompt.
    retryScript = ''
        set -u
        remaining="${lib.concatStringsSep " " clevisCfg.datasets}"

        # Puts a status line on the splash, silently doing nothing when no plymouthd is listening.
        splash() {
            ${plymouth} display-message --text="$1" > /dev/null 2>&1 || true
        }

        # Restarting an import cancels its outstanding password prompt, so it is only worth doing once something has actually unlocked.
        restart_imports() {
            # Once initrd.target is active the boot has moved on to switch-root, where restarting an import takes sysroot.mount down with it.
            if [ "$(${systemd}/bin/systemctl show -P ActiveState initrd.target 2>/dev/null || echo unknown)" = active ]; then
                echo "clevis-retry: initrd.target is already active, leaving the imports alone"
                return 0
            fi

            for unit in ${lib.concatStringsSep " " importServices}; do
                state="$(${systemd}/bin/systemctl show -P ActiveState "$unit" 2>/dev/null || echo unknown)"
                # Not "active": a unit sitting on a password prompt is activating, and restarting one that already succeeded tears down its mounts.
                case "$state" in
                    activating|failed)
                        echo "clevis-retry: restarting $unit (was $state)"
                        ${systemd}/bin/systemctl restart "$unit" || true
                        ;;
                    *)
                        echo "clevis-retry: $unit is $state, leaving it alone"
                        ;;
                esac
            done

            # Systemd never retries an already-failed job, so targets that failed by dependency have to be started explicitly.
            for unit in zfs-import.target initrd-fs.target; do
                state="$(${systemd}/bin/systemctl show -P ActiveState "$unit" 2>/dev/null || echo unknown)"
                if [ "$state" != active ]; then
                    echo "clevis-retry: starting $unit (was $state)"
                    ${systemd}/bin/systemctl start --no-block "$unit" || true
                fi
            done
        }

        while [ -n "$remaining" ]; do
            unlocked_this_round=false
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
                    splash "Unlocked $ds"
                    unlocked_this_round=true
                    continue
                fi
                still_locked="$still_locked''${still_locked:+ }$ds"
            done
            remaining="$still_locked"

            if [ "$unlocked_this_round" = true ]; then
                restart_imports
            fi

            [ -n "$remaining" ] || break
            splash "Waiting for tang to unlock: $remaining"
            sleep ${toString clevisCfg.retryInterval}
        done

        echo "clevis-retry: all clevis datasets unlocked"
        splash "All drives unlocked"

        # Always succeed: Restart=on-failure must never turn this into a restart loop.
        exit 0
    '';

    # Rebind Script ----------------------------------------------------------------------------------------------------------------------------------
    # Re-encrypts the ZFS passphrase against the current tang keys and writes one verified JWE per dataset.
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
            for url in ${lib.concatStringsSep " " tangCfg.urls}; do
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

            if [ "$reachable" -ne ${toString (builtins.length tangCfg.urls)} ]; then
                echo "rebind-clevis: WARNING - only $reachable of ${toString (builtins.length tangCfg.urls)} tang addresses responded." >&2
                echo "rebind-clevis: unreachable addresses are still bound but unverified." >&2
            fi

            install -d -m 0700 -o root -g root "${clevisCfg.stateDir}"

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
            '') clevisCfg.datasets}

            echo
            echo "rebind-clevis: all JWEs rebound and verified."
            echo "Apply them to the initrd with:"
            echo "  sudo nixos-rebuild boot --flake .#${config.networking.hostName}"
        '';
    };
in
{
    # Options ########################################################################################################################################
    options.technet.clevis = {
        enable = lib.mkEnableOption "clevis/tang ZFS unlocking at boot";

        rebindTool = {
            enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = ''
                    Install rebind-clevis and the zfs_passphrase secret it needs,
                    independently of whether unlocking at boot is enabled.

                    Deliberately separate, because the two have a chicken-and-egg
                    relationship: rebind-clevis is what *writes* the JWE, and
                    unlocking at boot is what consumes it. Gating the tool behind
                    `enable` means a freshly installed host cannot produce the JWE
                    without first turning on a feature that has nothing to read.

                    Defaults on. It costs one sops secret and one script, and
                    nothing it installs runs on its own -- rebind-clevis only does
                    anything when invoked by hand.
                '';
            };
        };

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

        retryInterval = lib.mkOption {
            type = lib.types.int;
            default = 5;
            description = ''
                Seconds clevis-retry waits between attempts at the datasets still
                locked.

                This is the pause *between* attempts, not the retry period: an
                attempt against an unreachable tang address costs whatever curl's
                connect timeout is, which clevis hardcodes. Shortening this alone
                does not make retries much more frequent unless that timeout is
                shortened too.
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
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = ''
                sops file holding zfs_passphrase for this host.

                Null means this host has nothing to unlock, and the whole module
                stays inert. That is not the same as `enable = false`:
                `rebindTool.enable` defaults on, so without this a host that
                never mentions clevis at all still reaches for the secret and
                fails to evaluate. Odin is exactly that case -- it runs the tang
                server the others unlock against and cannot unlock itself.
            '';
        };
    };

    config = lib.mkMerge [

        # Guards #####################################################################################################################################
        {
            assertions = [
                {
                    assertion = clevisCfg.enable -> clevisCfg.sopsFile != null;
                    message = "technet.clevis.enable is on for ${config.networking.hostName} but no sopsFile is set, so there is no zfs_passphrase to unlock with.";
                }
            ];
        }

        # Rebind Tool ################################################################################################################################
        # Available whether or not boot unlocking is on, so a new host can write its first JWE before enabling the feature that consumes it.
        (lib.mkIf ((clevisCfg.rebindTool.enable || clevisCfg.enable) && clevisCfg.sopsFile != null) {
            sops.secrets.zfs_passphrase = {
                sopsFile = clevisCfg.sopsFile;
                mode = "0400";
            };

            environment.systemPackages = [ rebindClevis ];
        })

        # Boot Unlock ################################################################################################################################
        (lib.mkIf clevisCfg.enable {
            boot.initrd = {
                clevis = {
                    enable = true;
                    useTang = true;
                    devices = lib.genAttrs clevisCfg.datasets (ds: {
                        secretFile = jweFile ds;
                    });
                };

                systemd.services = {
                    clevis-retry = {
                        description = "Keep retrying clevis/tang unlock in the background until it succeeds";
                        # Never make this blocking or ordered-before anything: the loop can run forever and would stall the initrd sshd needed to fix that.
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
                }
                # One splash line as each pool starts its tang unlock and import.
                // lib.listToAttrs (
                    map (
                        pool:
                        lib.nameValuePair "zfs-import-${pool}" {
                            serviceConfig.ExecStartPre = [ ''-${plymouth} display-message --text="Contacting tang to unlock ${pool}..."'' ];
                        }
                    ) pools
                );
            };
        })
    ];
}
