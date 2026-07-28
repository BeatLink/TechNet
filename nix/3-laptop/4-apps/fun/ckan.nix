{
    home-manager.users.beatlink =
        { config, pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ ckan ];
                persistence."/Storage/Apps/Fun/CKAN" = {
                    directories = [
                        ".local/share/CKAN"
                    ];

                };
            };
        };
}
