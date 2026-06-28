# Boot Loader
#
# This section manages misc boot settings
#

{
    boot = {
        loader.efi.canTouchEfiVariables = false;                            # Leaves Tow-Boot alone
        initrd.kernelModules = [ "phy_rockchip_inno_hdmi" "rockchipdrm" ];   # PHY must load before rockchipdrm or HDMI probe defers and screen goes blank
        kernelParams =  [
            "console=ttyS2,115200n8"
            "console=tty0"
        ];
    };
    services.journald.console = "/dev/ttyS2";                               # Mirror journal entries to serial (HDMI gets them via /dev/console)
}