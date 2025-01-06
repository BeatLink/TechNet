# Boot Loader ##########################################################################################################################
#
# This section manages misc boot settings
#
########################################################################################################################################

{ config, lib, pkgs, ... }:
{
    boot = {
        initrd = {
            verbose = false;
        };
        loader = {
            timeout = 0;
        };
        plymouth = {
            enable = true;
            #font = "${pkgs.noto-fonts}/share/fonts/truetype/DejaVuSans.ttf";
            theme = "breeze";
            /*themePackages = with pkgs; [
                # By default we would install all themes
                (adi1090x-plymouth-themes.override {
                selected_themes = [ "double" ];
            })
            ];*/
        };
        # Enable "Silent Boot"
        consoleLogLevel = 0;
        kernelParams = [
            "quiet"
            "splash"
            "boot.shell_on_fail"
            "loglevel=3"
            "rd.systemd.show_status=false"
            "rd.udev.log_level=3"
            "udev.log_priority=3"
        ];
    };
    services.fstrim.enable = true;
}