{
    imports = [
        ./hardware-configuration.nix
        ./boot.nix
        ./root-drive-disko.nix
        ./data-drive.nix
        ./software.nix
        ./networking.nix
        ./borg.nix
        ./clevis.nix
        ./remote-builder.nix
    ];
}
