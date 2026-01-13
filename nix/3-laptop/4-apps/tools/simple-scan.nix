{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ simple-scan ];
                persistence."/Storage/Apps/Tools/SimpleScan" = {
                    directories = [ ];

                };
            };
        };
}
