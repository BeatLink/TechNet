{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ czkawka ];
                persistence."/Storage/Apps/Tools/Czkawka" = {
                    directories = [
                        ".cache/czkawka"
                        ".config/czkawka"
                    ];

                };
            };
        };
}
