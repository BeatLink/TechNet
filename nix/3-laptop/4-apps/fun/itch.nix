{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = [
                    (pkgs.symlinkJoin {
                        name = "itch";
                        paths = [ pkgs.itch ];
                        nativeBuildInputs = [ pkgs.makeWrapper ];
                        # Its wrapper reads no NIXOS_OZONE_WL, so the flags that switch it off X11 are spelled out here
                        postBuild = ''
                            wrapProgram $out/bin/itch --add-flags "--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true"
                        '';
                    })
                ];
                persistence."/Storage/Apps/Fun/Itch" = {
                    directories = [
                        ".config/itch"
                        ".renpy"
                    ];

                };
            };
        };
}
