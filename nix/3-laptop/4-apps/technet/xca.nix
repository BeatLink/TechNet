{
    home-manager.users.beatlink =
        { pkgs, ... }:
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
