{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ pix ];
                persistence."/Storage/Apps/Tools/Pix" = {
                    directories = [
                        ".config/pix"
                    ];

                };
            };

            dconf.enable = true; # Enables dconf for Pix Setting Management
            imports = [
                # Imports Pix Dconf Settings
                ./2-dconf-settings.nix
            ];
        };
}
