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
        };
}
