# Overlays ###########################################################################################################################################
#
# Shims for packages whose upstream flakes have not caught up with the pinned nixpkgs.
#

{
    nixpkgs.overlays = [
        (final: prev: {
            buildGo125Module = prev.buildGo126Module; # sops-nix still calls this, and nixpkgs replaced it with a throw on 2026-09-15.
        })
    ];
}
