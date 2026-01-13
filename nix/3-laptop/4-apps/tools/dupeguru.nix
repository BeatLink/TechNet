{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ dupeguru ];
                persistence."/Storage/Apps/Tools/Dupeguru" = {
                    directories = [
                    ];

                };
            };
        };
}
