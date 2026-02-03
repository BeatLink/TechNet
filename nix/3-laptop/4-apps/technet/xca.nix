{
    home-manager.users.beatlink =
        { config, pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ xca ];
                persistence."/Storage/Apps/TechNet/XCA" = {
                    directories = [
                        ".config/xca"
                    ];

                };

            };

        };
}
