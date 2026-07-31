# Application Launchers
#
# Cinnamon's menu applet is a categorised menu: favourites down one side, application categories down the
# other, a search box, and session buttons along the bottom. Rofi is a flat search list, which covers the
# "type a few letters" half of that but not the "browse by category" half.
#
# Both are configured here:
#
#   nwg-menu   The MenuStart component of nwg-panel, run standalone. It renders the same shape as the
#              Cinnamon menu — categories, favourites, file manager and session buttons — and launches
#              through hyprctl. Bound to the menu button on the bar and to $mod.
#
#   rofi       Kept for keyboard-driven searching and for its window switcher.
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

            home.packages = [ pkgs.nwg-menu ];

            # nwg-menu sizes itself to its content, so filtering the list down to a single result collapsed
            # the window to one row tall. Fixing a minimum size on the window and the scrolled list keeps it
            # a stable shape while searching, the way the Cinnamon menu behaves.
            xdg.configFile."nwg-panel/menu-start.css".text = ''
                window {
                    background-color: rgba(30, 30, 30, 0.92);
                    color: #eeeeee;
                    min-width: 640px;
                    min-height: 620px;
                }

                scrolledwindow, list {
                    background: none;
                    border-radius: 12px;
                    min-height: 480px;
                }

                entry {
                    background-color: rgba(0, 0, 0, 0.25);
                    min-height: 34px;
                    margin: 4px;
                }

                button {
                    background: none;
                    border: none;
                }

                button:hover {
                    background-color: rgba(90, 192, 192, 0.18);
                }
            '';

            home.persistence."/Storage/Apps/System/Hyprland" = {
                files = [ ".cache/rofi3.druncache" ];
                # nwg-menu keeps its pinned favourites here; the stylesheet is managed above
                directories = [ ".cache/nwg-menu" ];
            };
        };
}
