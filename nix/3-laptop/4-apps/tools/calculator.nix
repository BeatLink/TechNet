{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ gnome-calculator ];
                persistence."/Storage/Apps/Tools/Calculator" = {
                    directories = [
                    ];

                };
            };
        };
}
