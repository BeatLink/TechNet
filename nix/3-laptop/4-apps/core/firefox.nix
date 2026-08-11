# Firefox
#
# Odin only. Thor reaches Firefox over waypipe instead of installing its own;
# what that needs on this side is in technet/phone-apps.nix.
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
