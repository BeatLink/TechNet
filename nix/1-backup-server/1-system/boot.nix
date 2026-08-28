# Boot ###############################################################################################################################################
#
# Console output for a headless board: the HDMI stack loaded from the initrd, and the serial console on ttyS2.
#

{ lib, ... }:
{
    config = lib.mkMerge [

        # HDMI Output ################################################################################################################################
        {
            boot.initrd.kernelModules = [
                "phy_rockchip_inno_hdmi" # Must load before rockchipdrm or the HDMI probe defers and the screen stays blank
                "rockchipdrm"
            ];
        }

        # Console Output #############################################################################################################################
        {
            boot.kernelParams = [
                "console=ttyS2,115200n8"
                "console=tty0" # Last console listed becomes /dev/console, so userspace output lands on HDMI
            ];
            services.journald.console = "/dev/ttyS2"; # Journal entries also go to serial; HDMI only sees what is written to /dev/console
        }
    ];
}
