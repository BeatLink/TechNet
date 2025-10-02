{ pkgs, lib, ... }:
{
    services = {
        displayManager.logToFile = false;
        displayManager.logToJournal = false;
        xserver = {
            enable = true; # Enables X11 Server
            displayManager.lightdm = {
                enable = true; # Enables LightDM Login Manager
                greeters.mobile.enable = true;
            };
            desktopManager.phosh = {
                enable = true;
                user = "beatlink";
                group = "beatlink";
                phocConfig.xwayland = "immediate";
            };
        };
    };
    # unpatched gnome-initial-setup is partially broken in small screens
    #services.gnome.gnome-initial-setup.enable = false;

    #programs.phosh.enable = true;
    #environment.gnome.excludePackages = with pkgs.gnome3; [

    #];
    environment.systemPackages = with pkgs; [
        git
        gnome-terminal
        pipes
        wget
    ];

    environment.etc."machine-info".text = lib.mkDefault ''
        CHASSIS="handset"
    '';

}
