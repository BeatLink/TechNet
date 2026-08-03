{ pkgs, lib, ... }:
{
    # phocConfig sets xwayland = "immediate" below, and dropping
    # services.xserver.enable took Xwayland with it. Enabled directly so X11
    # applications still work; this pulls in the Xwayland binary only, not a
    # display manager.
    programs.xwayland.enable = true;

    services = {
        # No display manager. The phosh module does not use one -- it runs
        # phosh-session directly as a systemd service under `user`, with
        # PAMName = "login", and says so in its own source: "We are running
        # without a display manager". Phosh then presents its own lock screen,
        # which has the on-screen keypad a phone needs.
        #
        # services.xserver.enable would undo that. It turns on LightDM by
        # default, and both then run at once: lightdm-gtk-greeter took
        # /dev/dri/card1 and put a desktop login box with a password field and no
        # on-screen keyboard in front of a device with no keyboard, while phoc
        # ran alongside it. That is the same two-display-managers-fighting
        # problem documented for Odin in CLAUDE.md.
        #
        # displayManager.autoLogin and defaultSession were configured but dead:
        # nothing consumes them without a display manager, so they were not the
        # reason a login screen appeared, and removing the greeter is what
        # actually fixes it.
        xserver = {
            desktopManager.phosh = {
                enable = true;
                user = "beatlink";
                group = "beatlink";
                phocConfig = {
                    xwayland = "immediate";
                    outputs = {
                        DSI-1 = {
                            scale = 2;
                            rotate = "90";
                            mode = "720x1440";
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
