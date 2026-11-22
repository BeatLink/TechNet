{
    imports = [
        ./hardware-configuration.nix
        ./boot.nix
        ./root-drive-disko.nix
        ./swap.nix
        ./data-drive.nix
        ./software.nix
        ./networking.nix
        ./borg.nix
        ./clevis.nix
        ./freeze-recovery.nix
    ];
}
