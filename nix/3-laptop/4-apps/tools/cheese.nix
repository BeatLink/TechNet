{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ cheese ];
                persistence."/Storage/Apps/Tools/Cheese" = {
                    directories = [
                    ];

                };
            };
        };
}
