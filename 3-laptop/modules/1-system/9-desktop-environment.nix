{ config, pkgs, ... }:
{  
    services.libinput.enable = true;
    services.xserver = {
        enable = true;
        displayManager.lightdm.enable = true;
        desktopManager.cinnamon.enable = true;
        xkb = {
            layout = "us";
            variant = "";
        };
    };
}