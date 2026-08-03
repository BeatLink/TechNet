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
}
