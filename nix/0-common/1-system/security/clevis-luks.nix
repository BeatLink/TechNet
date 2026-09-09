# Clevis (LUKS) ######################################################################################################################################
#
# Keeps retrying the tang unlock for LUKS devices until it succeeds, then restarts the cryptsetup unit that was left sitting on a password prompt.
#
# The counterpart of the ZFS retry loop in clevis.nix, and the same shape: nixpkgs decrypts the JWE once, before systemd-cryptsetup, which is too
# early on a host whose tang servers are reached over wifi brought up in the initrd. This runs after that first attempt has already failed.
#
# It drives nixpkgs' own cryptsetup-clevis-<device> unit rather than decrypting itself. That unit owns the ramfs holding the key, and its ExecStop
# unmounts it, so a restart replaces the key cleanly. Writing the key here instead would be undone: the unit is wantedBy systemd-cryptsetup, so
# restarting cryptsetup re-runs the failed decrypt, whose `mount -t ramfs` stacks an empty filesystem over whatever was written.
#

{ config, lib, pkgs, utils, ... }:
let
    clevisCfg = config.technet.clevis;

    # Helpers ----------------------------------------------------------------------------------------------------------------------------------------
    systemctl = "${config.boot.initrd.systemd.package}/bin/systemctl";

    cryptsetupUnit = device: "systemd-cryptsetup@${utils.escapeSystemdPath device}.service";
    clevisUnit = device: "cryptsetup-clevis-${device}.service";

    # A wrong key unlocks nothing no matter how often it is retried, and every restart cancels the password prompt the user would type into instead
    maxAttempts = 5;

    # Retry Loop -------------------------------------------------------------------------------------------------------------------------------------
    retryScript = ''
        set -u
        remaining="${lib.concatStringsSep " " clevisCfg.luksDevices}"

        state() {
            ${systemctl} show -P ActiveState "$1" 2>/dev/null || echo unknown
        }

        while [ -n "$remaining" ]; do
            still_locked=""
            for dev in $remaining; do
                case "$dev" in
${lib.concatMapStringsSep "\n" (device: "                    ${device}) cryptunit=\"${cryptsetupUnit device}\"; clevisunit=\"${clevisUnit device}\" ;;") clevisCfg.luksDevices}
                    *) echo "clevis-luks-retry: no units known for $dev"; continue ;;
                esac

                if [ "$(state "$cryptunit")" = active ]; then
                    echo "clevis-luks-retry: $dev is open"
                    continue
                fi

                # Once initrd.target is active the boot has moved on to switch-root, where restarting cryptsetup takes sysroot.mount down with it.
                if [ "$(state initrd.target)" = active ]; then
                    echo "clevis-luks-retry: initrd.target is already active, leaving $dev alone"
                    continue
                fi

                counter="/run/clevis-luks-retry.$dev"
                attempts="$(cat "$counter" 2>/dev/null || echo 0)"
                if [ "$attempts" -ge ${toString maxAttempts} ]; then
                    echo "clevis-luks-retry: $dev still locked after $attempts attempts, leaving the password prompt alone"
                    continue
                fi

                case "$(state "$clevisunit")" in
                    activating)
                        # Its first decrypt is still in flight; restarting now would throw away an attempt that may yet succeed
                        echo "clevis-luks-retry: $clevisunit is still trying, leaving it alone"
                        ;;
                    active)
                        # The key is already decrypted and in place, so only cryptsetup needs another go at it
                        echo "$((attempts + 1))" > "$counter"
                        echo "clevis-luks-retry: key for $dev is ready, restarting $cryptunit"
                        ${systemctl} restart "$cryptunit" || true
                        ;;
                    *)
                        echo "$((attempts + 1))" > "$counter"
                        if ${systemctl} restart "$clevisunit"; then
                            echo "clevis-luks-retry: decrypted the key for $dev, restarting $cryptunit"
                            ${systemctl} restart "$cryptunit" || true
                        else
                            echo "clevis-luks-retry: $clevisunit failed again, tang is still out of reach"
                        fi
                        ;;
                esac

                # Kept in the list either way: the next round's state check is what decides whether the restart actually opened it
                still_locked="$still_locked''${still_locked:+ }$dev"
            done
            remaining="$still_locked"

            [ -n "$remaining" ] || break
            sleep ${toString clevisCfg.retryInterval}
        done

        echo "clevis-luks-retry: nothing left to unlock"

        # Always succeed: Restart=on-failure must never turn this into a restart loop.
        exit 0
    '';
in
{
    config = lib.mkIf (clevisCfg.enable && clevisCfg.luksDevices != [ ]) {
        boot.initrd.systemd.services.clevis-luks-retry = {
            description = "Keep retrying the clevis/tang unlock of the LUKS devices until it succeeds";
            # Never make this blocking or ordered-before anything: the loop can run forever and would stall the initrd sshd needed to fix that.
            wantedBy = [ "initrd.target" ];
            after = [ "systemd-modules-load.service" ];
            path = [ pkgs.coreutils ];
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
}
