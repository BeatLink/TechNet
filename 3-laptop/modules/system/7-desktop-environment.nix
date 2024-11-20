{ config, pkgs, ... }:
{  
    services.xserver = {
        enable = true;
        displayManager.lightdm.enable = true;
        desktopManager.cinnamon.enable = true;
        libinput.enable = true;
        xkb = {
            layout = "us";
            variant = "";
        };
    };
}