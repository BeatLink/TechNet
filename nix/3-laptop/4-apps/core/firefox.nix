# Firefox
#
# Odin only. Thor reaches Firefox over waypipe instead of installing its own,
# and what that needs is declared on Heimdall, which runs it.
#
{ pkgs, ... }:
{
    programs.firefox = {
        enable = true;
        nativeMessagingHosts.packages = with pkgs; [
            firefoxpwa
            keepassxc
        ];
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
