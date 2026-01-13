{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ itch ];
                persistence."/Storage/Apps/Fun/Itch" = {
                    directories = [
                        ".config/itch"
                        ".renpy"
                    ];

                };
            };
        };
}
