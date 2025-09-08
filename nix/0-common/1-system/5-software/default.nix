# Software
#
# Configures Software in NixOS

{
    imports = [
        ./1-flakes.nix
        ./2-updates.nix
        ./3-garbage-collection.nix
        ./4-unfree-packages.nix
        ./5-default-packages.nix
    ];
}
