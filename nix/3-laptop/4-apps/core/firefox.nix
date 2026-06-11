{ pkgs, ... }:
{
    programs.firefox = {
        enable = true;
        package = pkgs.firefox;
        nativeMessagingHosts.packages = with pkgs; [
            firefoxpwa
            keepassxc
        ];
    };

    home-manager.users.beatlink =
        {
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
