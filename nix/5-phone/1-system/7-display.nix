{ pkgs, lib, ... }:
{
    services = {
        displayManager = {
            enable = true;
            autoLogin = {
                enable = true;
                user = "beatlink";
            };
            defaultSession = "phosh";
        };
        xserver = {
            enable = true;
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

    #environment.gnome.excludePackages = with pkgs.gnome3; [

    #];
    environment.systemPackages = with pkgs; [
        gnome-terminal
        pipes
        phosh-mobile-settings
    ];

    environment.etc."machine-info".text = lib.mkDefault ''
        CHASSIS="handset"
    '';

}
