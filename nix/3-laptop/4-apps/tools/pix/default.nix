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

            dconfImports = {
                org-x-pix = {
                    source = ./2-dconf-settings.ini;
                    path = "/org/x/pix/";
                };
            };

            dconf.enable = true; # Enables dconf for Pix Setting Management
        };
}
