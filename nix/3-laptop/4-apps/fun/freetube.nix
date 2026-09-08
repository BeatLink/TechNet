# FreeTube
#
# Odin only. Thor displays Heimdall's copy over waypipe rather than installing
# one of its own.
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
