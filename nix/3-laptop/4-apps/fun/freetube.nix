{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ freetube ];
                persistence."/Storage/Apps/Fun/FreeTube" = {
                    directories = [
                        ".config/FreeTube"
                        ".config/freetube-waypipe" # Electron userData for the instance Thor opens over waypipe, beside this one rather than inside it
                    ];

                };
            };
        };
}
