{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ inkscape ];
                persistence."/Storage/Apps/Tools/Inkscape" = {
                    directories = [
                        ".cache/inkscape"
                        ".config/inkscape"
                    ];

                };
            };
        };
}
