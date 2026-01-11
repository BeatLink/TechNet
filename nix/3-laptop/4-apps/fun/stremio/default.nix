{
    nixpkgs.config.permittedInsecurePackages = [
        # needed until new stremio frontend is stable
        "qtwebengine-5.15.19"
    ];
    home-manager.users.beatlink =
        { inputs, ... }:
        let
            pkgs-stable = import inputs.nixpkgs-stable {
                system = "x86_64-linux";
                config.allowUnfree = true;
                #config.permittedInsecurePackages = [
                #    "qtwebengine-5.15.19"
                #];
            };
        in
        {
            home = {
                packages = [ pkgs-stable.stremio ]; # (pkgs.callPackage ./stremio.nix {}) ];
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
