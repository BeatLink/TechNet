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
                packages = [
                    (pkgs.symlinkJoin {
                        name = "freetube";
                        paths = [ pkgs.freetube ];
                        nativeBuildInputs = [ pkgs.makeWrapper ];
                        # NIXOS_OZONE_WL gets the wrapper as far as the decorations and the IME, but it adds no ozone platform at all, so Electron still picks X11
                        postBuild = ''
                            wrapProgram $out/bin/freetube --add-flags "--ozone-platform-hint=auto"
                        '';
                    })
                ];

                persistence."/Storage/Apps/Fun/FreeTube" = {
                    directories = [
                        ".config/FreeTube"
                    ];

                };
            };
        };
}
