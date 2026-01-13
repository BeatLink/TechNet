{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ sqlitebrowser ];
                persistence."/Storage/Apps/Programming/SQLiteBrowser" = {
                    directories = [
                        ".config/sqlitebrowser"
                    ];

                };
            };
        };
}
