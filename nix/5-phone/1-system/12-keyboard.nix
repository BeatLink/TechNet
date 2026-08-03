# Keyboard accessory
#
# The PinePhone keyboard case attaches over the pogo pins and presents two
# devices on I2C: a keyboard MCU, and an Injoinic IP5209 power bank chip holding
# the case's own 6000 mAh cell.
#
# Charging is autonomous -- the IP5209 charges its cell and feeds the phone
# whether or not anything here is loaded. What these drivers add is the keys
# working, and the case's charge level being visible alongside the phone's own
# battery rather than the pack being invisible.
#
# Charge the case through ITS usb-c port, not the phone's. The case already
# supplies 5V to the phone over the pogo pins, and feeding the phone's port at
# the same time drives two sources into one rail.
#
{ pkgs, ... }:
{
    # ip5xxx_power, for the case's own battery via its IP5209, is `=y` in megi's
    # kernel and needs no declaration.
    #
    # pinephone_keyboard is a different matter: mobile-nixos' config has
    # `# CONFIG_KEYBOARD_PINEPHONE is not set`, so the driver megi's tree carries
    # is not actually built. Declaring it only produced a modprobe failure every
    # boot. Enabling it means adding the option to the kernel config in
    # PinePhoneKernel, not listing it here -- see TODO.md.
    boot.kernelModules = [ ];

    # The keyboard sits on an i2c bus; i2c-dev makes it reachable from userspace
    # for the flashing and diagnostic tools, which is the only way to inspect the
    # MCU when the input driver does not bind.
    hardware.i2c.enable = true;

    # i2c has no hotplug detection. The driver probes once at boot and logs
    # "Keyboard was not found on the I2C bus" if the case is off, and nothing
    # re-probes it later. The device node stays instantiated because the DT node
    # is static, so a bind is all that is needed -- but something has to ask.
    #
    # Attaching the case puts 5V on the pogo pins, which the AXP803 sees as a
    # VBUS change and udev reports as a power_supply event. That is the only
    # attach signal this hardware produces. It does NOT fire when the phone is
    # already on a charger, since VBUS is present either way; run
    # `systemctl start pinephone-keyboard-bind` by hand in that case.
    systemd.services.pinephone-keyboard-bind = {
        description = "Bind the PinePhone keyboard case if it is attached";
        serviceConfig = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "pinephone-keyboard-bind" ''
                driver=/sys/bus/i2c/drivers/pinephone-keyboard
                [ -e "$driver/3-0015" ] && exit 0
                [ -e /sys/bus/i2c/devices/3-0015 ] || exit 0
                echo 3-0015 > "$driver/bind" 2>/dev/null || true
            '';
        };
    };

    # systemctl rather than RUN+= directly: a udev RUN rule blocks the worker
    # until it returns, and writing to a driver's bind attribute from inside one
    # deadlocks against the uevents that bind itself emits.
    services.udev.extraRules = ''
        SUBSYSTEM=="power_supply", ACTION=="change", RUN+="${pkgs.systemd}/bin/systemctl --no-block start pinephone-keyboard-bind.service"
    '';
}
