# Rofi
#
# Rofi replaces the KDE Kickoff application launcher. The wayland fork is used so it runs natively rather than
# through XWayland.
#

{ pkgs, ... }:
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            programs.rofi = {
                enable = true;
                terminal = "${pkgs.tilix}/bin/tilix";
                extraConfig = {
                    modi = "drun,run,window";
                    show-icons = true;
                    icon-theme = "Mint-Y-Aqua";
                    drun-display-format = "{name}";
                    display-drun = "Apps";
                    display-window = "Windows";
                };
            };

            home.persistence."/Storage/Apps/System/Hyprland" = {
                files = [ ".cache/rofi3.druncache" ];
            };
        };
}
