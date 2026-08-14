{

    home-manager.users.beatlink = { inputs, pkgs, ... }: {
        home = {
            packages = [ inputs.app-separators.packages.${pkgs.stdenv.hostPlatform.system}.default ];
            persistence."/Storage/Apps/Tools/App-Separator" = {
                directories = [
                    ".local/share/applications/app-separator"
                ];

            };
        };
    };

}
