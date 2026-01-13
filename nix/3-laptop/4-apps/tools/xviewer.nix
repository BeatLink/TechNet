{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ xviewer ];
                persistence."/Storage/Apps/Tools/XViewer" = {
                    directories = [
                        ".config/xviewer"
                    ];

                };
            };
        };
}
