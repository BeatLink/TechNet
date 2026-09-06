{
    imports = [
        ./hardware-configuration.nix
        ./boot.nix
        ./root-drive-disko.nix
        ./swap.nix
        ./data-drive.nix
        ./smart.nix
        ./software.nix
        ./networking.nix
        ./borg.nix
        ./clevis.nix
        ./remote-builder.nix
    ];
}
