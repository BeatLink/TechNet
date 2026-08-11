# FreeTube
#
# Thor opens a second instance of this over waypipe, running here under its own
# Electron user data dir; what that needs on this side is in technet/phone-apps.nix.
#
{ ... }:
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ freetube ];

                persistence."/Storage/Apps/Fun/FreeTube" = {
                    directories = [
                        ".config/FreeTube"
                    ];

                };
            };
        };
}
