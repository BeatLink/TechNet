# Boot ###############################################################################################################################################
#
# Console output for a headless board: the HDMI stack loaded from the initrd, and the serial console on ttyS2.
# Also the clock, whose RTC has no battery.
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

        # Clock ######################################################################################################################################
        {
            # Loaded from the initrd so RTC_HCTOSYS sets the clock at boot; as a normal module it lands 90s in, and everything logged before that is
            # stamped with systemd's build epoch, which makes boot time ranges overlap and `journalctl -b -1` select the wrong boot.
            boot.initrd.kernelModules = [ "rtc_rk808" ];
        }

        # Console Output #############################################################################################################################
        {
            boot.kernelParams = [
                "console=ttyS2,115200n8"
                "console=tty0" # Last console listed becomes /dev/console, so userspace output lands on HDMI
            ];
            # Journal entries also go to serial; HDMI only sees what is written to /dev/console
            services.journald.settings.Journal = {
                ForwardToConsole = true;
                TTYPath = "/dev/ttyS2";
            };
        }
    ];
}
