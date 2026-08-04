# Firefox
#
# Identical on both hosts, so all of it is shared. Odin adds its native
# messaging hosts (firefoxpwa, keepassxc) from 3-laptop -- programs.firefox
# merges across modules, so that stays a small block there rather than becoming
# an option here.
#
{ pkgs, ... }:
{
    programs.firefox = {
        enable = true;
        package = pkgs.firefox;
    };

    home-manager.users.beatlink = {
        home = {
            persistence."/Storage/Apps/Core/Firefox" = {
                directories = [
                    ".cache/mozilla/firefox"
                    ".config/mozilla/firefox"
                    ".local/share/mozilla/firefox"
                ];
            };
        };
    };
}
