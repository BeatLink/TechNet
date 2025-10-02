{ pkgs, lib, ... }:
{
    services = {
        displayManager.logToFile = false;
        displayManager.logToJournal = false;
        xserver = {
            enable = true; # Enables X11 Server
            desktopManager.phosh = {
                enable = true;
                user = "beatlink";
                group = "beatlink";
                phocConfig = {
                    xwayland = "immediate";
                    outputs = {
                        eDP-1 = {
                            scale = 2;
                            # optional: you can override resolution if needed
                            # mode = "720x1440";
                        };
                    };

                };
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
        phosh-mobile-settings
    ];

    environment.etc."machine-info".text = lib.mkDefault ''
        CHASSIS="handset"
    '';

}
