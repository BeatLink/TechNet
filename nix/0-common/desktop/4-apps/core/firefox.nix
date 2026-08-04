# Firefox
#
# The persistence and the enable are shared. What differs is per-host and set
# next to each host's other overrides, because programs.firefox merges across
# modules: Odin adds its native messaging hosts (firefoxpwa, keepassxc), and
# Thor swaps the package for the mobile build.
#
# mkDefault on the package so Thor can replace it without mkForce.
#
{ lib, pkgs, ... }:
{
    programs.firefox = {
        enable = true;
        package = lib.mkDefault pkgs.firefox;
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
