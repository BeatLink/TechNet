{ pkgs, ... }:
{
    nixpkgs.config.permittedInsecurePackages = [ # needed until new stremio frontend is stable
        "qtwebengine-5.15.19"
    ];
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            nixpkgs.config.permittedInsecurePackages = [
                "qtwebengine-5.15.19"
            ];
            home = {
                packages = [ pkgs.stremio ]; # (pkgs.callPackage ./stremio.nix {}) ];
                persistence."/Storage/Apps/Fun/Stremio" = {
                    directories = [
                        ".cache/Smart Code ltd"
                        ".config/Smart Code ltd"
                        ".local/share/Smart Code ltd"
                        ".stremio-server"
                    ];
                    allowOther = true;
                };
            };
        };
}
