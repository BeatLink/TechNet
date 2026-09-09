# Clevis (LUKS) ######################################################################################################################################
#
# Keeps retrying the tang unlock for LUKS devices until it succeeds, then restarts the cryptsetup unit that was left sitting on a password prompt.
#
# The counterpart of the ZFS retry loop in clevis.nix, and the same shape: nixpkgs decrypts the JWE once, before systemd-cryptsetup, which is too
# early on a host whose tang servers are reached over wifi brought up in the initrd. This runs after that first attempt has already failed.
#

{ config, lib, pkgs, ... }:
let
    clevisCfg = config.technet.clevis;

    # Helpers ----------------------------------------------------------------------------------------------------------------------------------------
    clevis = "${config.boot.initrd.clevis.package}/bin/clevis";
    cryptsetup = "${pkgs.cryptsetup}/bin/cryptsetup";
    systemctl = "${config.boot.initrd.systemd.package}/bin/systemctl";

    # Retry Loop -------------------------------------------------------------------------------------------------------------------------------------
    retryScript = ''
        set -u
        remaining="${lib.concatStringsSep " " clevisCfg.luksDevices}"

        # Restarting the unit cancels its outstanding password prompt, so it is only worth doing once a key has actually been written.
        restart_unit() {
            # Once initrd.target is active the boot has moved on to switch-root, where restarting cryptsetup takes sysroot.mount down with it.
            if [ "$(${systemctl} show -P ActiveState initrd.target 2>/dev/null || echo unknown)" = active ]; then
                echo "clevis-luks-retry: initrd.target is already active, leaving $1 alone"
                return 0
            fi

            unit="systemd-cryptsetup@$1.service"
            state="$(${systemctl} show -P ActiveState "$unit" 2>/dev/null || echo unknown)"
            # Not "active": a unit sitting on a password prompt is activating, and restarting one that already succeeded tears down its mounts.
            case "$state" in
                activating|failed)
                    echo "clevis-luks-retry: restarting $unit (was $state)"
                    ${systemctl} restart "$unit" || true
                    ;;
                *)
                    echo "clevis-luks-retry: $unit is $state, leaving it alone"
                    ;;
            esac
        }

        while [ -n "$remaining" ]; do
            still_locked=""
            for dev in $remaining; do
                if ${cryptsetup} status "$dev" >/dev/null 2>&1; then
                    echo "clevis-luks-retry: $dev already unlocked"
                    continue
                fi

                # The path nixpkgs points the device's keyFile at, so writing here is all that is needed to arm the next cryptsetup attempt.
                keydir="/clevis-$dev"
                jwe="/etc/clevis/$dev.jwe"
                mkdir -p "$keydir"
                case "$(cat /proc/self/mounts)" in
                    *" $keydir "*) ;;
                    *) mount -t ramfs none "$keydir" ;;
                esac

                if [ -r "$jwe" ] && ( umask 277; ${clevis} decrypt < "$jwe" > "$keydir/decrypted" ) 2>/dev/null; then
                    echo "clevis-luks-retry: wrote key for $dev"
                    restart_unit "$dev"
                fi

                # Kept in the list either way: the next round's status check is what decides whether the restart actually opened it.
                still_locked="$still_locked''${still_locked:+ }$dev"
            done
            remaining="$still_locked"

            [ -n "$remaining" ] || break
            sleep ${toString clevisCfg.retryInterval}
        done

        echo "clevis-luks-retry: all clevis devices unlocked"

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
            path = with pkgs; [
                util-linux
                coreutils
            ];
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
