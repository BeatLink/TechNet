{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ baobab ];
                persistence."/Storage/Apps/System/Baobab" = {

                };
            };
        };
}
