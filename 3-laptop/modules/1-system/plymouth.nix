# Boot Loader
#
# This section manages misc boot settings
#

{ pkgs, ... }:
{
    boot = {
        initrd.verbose = false;
        plymouth = {
            enable = true;
            #font = "${pkgs.noto-fonts}/share/fonts/truetype/DejaVuSans.ttf";
            theme = "spinner_alt";
            themePackages = with pkgs; [
                # By default we would install all themes
                (adi1090x-plymouth-themes.override {
                selected_themes = [ "spinner_alt" ];
            })
            ];
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
}