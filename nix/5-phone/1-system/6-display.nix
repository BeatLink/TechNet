{ pkgs, lib, ... }:
{
    # Xwayland #######################################################################################################################################

    programs.xwayland.enable = false;

    # Qt defaults to xcb, and there is no X server here.
    environment.sessionVariables.QT_QPA_PLATFORM = "wayland";

    # Compositor #####################################################################################################################################

    services = {
        xserver = {
            desktopManager.phosh = {
                enable = true;
                user = "beatlink";
                group = "beatlink";
                phocConfig = {
                    xwayland = "false";
                    outputs = {
                        DSI-1 = {
                            scale = 1.5;
                            mode = "720x1440";
                        };

                        HDMI-A-1 = {
                            mode = "1920x1080";
                            scale = 1;
                        };
                    };
                };
            };
        };

        avahi.enable = false;
    };

    # Session ########################################################################################################################################

    # Start the session only once home-manager has linked the user's units.
    systemd.services.phosh.after = [ "systemd-user-sessions.service" ];

    # Restart phosh in one step instead of stopping it for the whole switch.
    systemd.services.phosh.stopIfChanged = false;

    # tty1 belongs to phosh.
    systemd.targets.getty.wants = lib.mkForce [ ];

    # Backlight ######################################################################################################################################

    # After systemd-backlight, which would otherwise land after this and undo it.
    systemd.services.backlight-max = {
        description = "Set the panel backlight to maximum at boot";
        wantedBy = [ "multi-user.target" ];
        after = [ "systemd-backlight@backlight:backlight.service" ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "backlight-max" ''
                for panel in /sys/class/backlight/*; do
                    [ -e "$panel/max_brightness" ] || continue
                    cat "$panel/max_brightness" > "$panel/brightness"
                done
            '';
        };
    };

    # Shell settings #################################################################################################################################

    # Exported to dconf/shell; edit on the phone, then nixtool run maintenance/export-dconf
    programs.dconf.profiles.user.databases = [
        {
            settings = {
                "org/gnome/desktop/interface".show-battery-percentage = true;
            };
        }
    ];

    # Packages #######################################################################################################################################

    environment.systemPackages = with pkgs; [
        gnome-terminal
        pipes
        phosh-mobile-settings
        hunspellDicts.en_US
    ];

    documentation.nixos.enable = false;
    environment.gnome.excludePackages = [ pkgs.gnome-tour ];

    environment.etc."machine-info".text = lib.mkDefault ''
        CHASSIS="handset"
    '';
}
