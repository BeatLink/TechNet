# Firefox
#
# Odin only. Thor reaches Firefox over waypipe instead of installing its own, so
# what used to be shared under 0-common lives here now -- including the
# persistence, which on Thor was bind-mounting a profile for a browser that was
# no longer installed.
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
                    # A second profile root, deliberately beside the first rather than inside it, holding the copy Thor opens over waypipe
                    ".config/mozilla/firefox-waypipe"
                    ".local/share/mozilla/firefox"
                ];
            };
        };
    };
}
