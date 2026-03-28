{
    home-manager.users.beatlink =
        { inputs, pkgs, ... }:
        let
            pkgs-stremio = import inputs.stremio-fix {
                system = pkgs.system;
                config.allowUnfree = true;
            };
        in
        {
            home = {
                packages = [ pkgs-stremio.stremio-linux-shell ];
                persistence."/Storage/Apps/Fun/Stremio" = {
                    directories = [
                        ".cache/Smart Code ltd"
                        ".config/Smart Code ltd"
                        ".local/share/Smart Code ltd"
                        ".local/share/stremio"
                        ".stremio-server"
                    ];

                };
            };
        };
}
