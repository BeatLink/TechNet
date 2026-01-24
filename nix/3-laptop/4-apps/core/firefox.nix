{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ firefox ];
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
