# Battery and USB charging
#
# The PinePhone's PMIC is an X-Powers AXP803, driven by the axp20x family. It
# owns both the battery gauge and the USB input, so the two are configured
# together: what reports charge and what supplies it are the same chip.
#
# USB-C role and power negotiation are NOT handled here, and cannot be on a
# mainline kernel. The port is behind an Analogix ANX7688, whose driver has
# never been merged -- `anx7688` is absent from this kernel, confirmed against
# the built module tree. The practical effect is that the phone charges from a
# plain 5V supply through the AXP803, but does not negotiate USB-PD and does not
# switch roles on its own.
#
{ lib, ... }:
{
    boot.kernelModules = [
        "axp20x_battery" # Battery gauge
        "axp20x_usb_power" # USB input, and what charging current is drawn
        "typec"
        "typec_ucsi"
    ];

    # upower is what desktop shells read for charge level and time remaining; the
    # kernel drivers above only expose /sys/class/power_supply.
    services.upower = {
        enable = true;
        # A phone should warn earlier than a laptop: there is no second battery
        # and no warning from a lid closing.
        percentageLow = 20;
        percentageCritical = 10;
        percentageAction = 5;
        criticalPowerAction = "PowerOff";
    };

    # Suspend on idle is left to the desktop rather than logind, so that a long
    # running task over the serial console or SSH is not cut off mid-way.
    services.logind.settings.Login = {
        HandlePowerKey = lib.mkDefault "suspend";
        IdleAction = lib.mkDefault "ignore";
    };
}
