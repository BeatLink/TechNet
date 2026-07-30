{
    home-manager.users.beatlink =
        { config, pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ lutris ];
                persistence."/Storage/Apps/Fun/Lutris" = {
                    directories = [
                        ".cache/lutris"
                        ".config/lutris"
                        ".local/share/lutris"
                    ];

                };
            };
        };
}
