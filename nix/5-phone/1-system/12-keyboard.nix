# Keyboard accessory
#
# The case is a keyboard MCU plus an Injoinic IP5209 power bank on i2c, and this
# binds both to whether it is actually attached. Charge the case through ITS
# usb-c port, not the phone's, which would drive two sources into one rail.
#
{ pkgs, ... }:
{
    # Empty on purpose: the driver is `# CONFIG_KEYBOARD_PINEPHONE is not set` in mobile-nixos, so declaring it here only fails modprobe -- see TODO.md.
    boot.kernelModules = [ ];

    hardware.i2c.enable = true;

    # Attach and detach are both invisible to i2c, so this resyncs on the VBUS change udev reports; it does NOT fire when the phone is already on a charger, so run it by hand in that case.
    systemd.services.pinephone-keyboard-sync = {
        description = "Bind the PinePhone keyboard case, and keyd, to whether the case is attached";
        wantedBy = [ "multi-user.target" ];

        # A VBUS change arrives as a burst of power_supply events, which trips the default 5-starts-in-10s limit and makes systemd refuse the attach that follows.
        startLimitIntervalSec = 0;
        serviceConfig = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "pinephone-keyboard-sync" ''
                driver=/sys/bus/i2c/drivers/pinephone-keyboard

                status=/sys/class/power_supply/ip5xxx-battery/status

                # Reading the case's own battery is the only presence test that does not disturb a working bind; a node that is absent has not enumerated yet and proves nothing, only one that reads back an error proves the case is gone.
                stale() {
                    [ -e "$status" ] || return 1

                    # Retried, because a single bus timeout here would unbind a keyboard that is still attached and working.
                    for _ in 1 2 3; do
                        ${pkgs.coreutils}/bin/cat "$status" > /dev/null 2>&1 && return 1
                        ${pkgs.coreutils}/bin/sleep 1
                    done
                    return 0
                }

                if [ -e "$driver/3-0015" ]; then
                    if stale; then
                        echo 3-0015 > "$driver/unbind" 2>/dev/null || true
                    fi
                else
                    echo 3-0015 > "$driver/bind" 2>/dev/null || true
                fi

                # keyd's virtual keyboard reads as a hardware keyboard to phoc, which suppresses the on-screen keyboard, so it may only run while the case is on.
                if [ -e "$driver/3-0015" ]; then
                    ${pkgs.systemd}/bin/systemctl start keyd.service
                else
                    ${pkgs.systemd}/bin/systemctl stop keyd.service
                fi
            '';
        };
    };

    # systemctl rather than RUN+= directly, which would deadlock the udev worker against the uevents bind itself emits.
    services.udev.extraRules = ''
        SUBSYSTEM=="power_supply", ACTION=="change", RUN+="${pkgs.systemd}/bin/systemctl --no-block start pinephone-keyboard-sync.service"
    '';
}
