# Boot Loader ##########################################################################################################################
#
# This section manages misc boot settings
#
########################################################################################################################################

{ config, lib, pkgs, ... }:
{
    boot = {
        supportedFilesystems = [ "zfs" ];                               # Needed for impermanence
        loader = {
            systemd-boot.enable = true;                                 # Use Systemd-Boot to manage booting
            grub.enable = false;                                        # Disable Grub since we're using Systemd-Boot
            efi.canTouchEfiVariables = true;                            # Allows setting boot order, UEFI settings, etc
            timeout = 0;
        };
        initrd = {
            supportedFilesystems = [ "zfs" ];                           # Needed for impermanence
            systemd.enable = true;
            verbose = false;
    
        };
        /*plymouth = {
            enable = true;
            theme = "double";
            themePackages = with pkgs; [
                # By default we would install all themes
                (adi1090x-plymouth-themes.override {
                selected_themes = [ "double" ];
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
        ];*/
    };
    services.fstrim.enable = true;
}