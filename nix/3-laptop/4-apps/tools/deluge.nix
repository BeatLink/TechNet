{ config, pkgs, ... }:
{
    home-manager.users.beatlink =
        { config, pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ deluge ];
                persistence."/Storage/Apps/Tools/Deluge" = {
                    directories = [
                        ".config/deluge"
                    ];

                };
            };
        };
}
