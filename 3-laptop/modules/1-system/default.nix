# Laptop Configuration
#
# TODO: Add Notes
#

{
    imports = [                                   
        ./1-hardware-configuration.nix
        ./2-boot.nix
        ./3-root-drive-disko.nix
        ./4-disko-data-drive.nix
        ./6-sops.nix
        ./7-software.nix
        ./8-networking.nix
        ./10-display.nix
        ./11-sound.nix
        ./12-bluetooth.nix
        ./13-printing.nix
        ./14-fuse.nix
        ./15-home-folders.nix
        ./plymouth.nix
        ./desktop-environment

    ];

    home-manager.users.beatlink = {
        imports = [./dconf.nix];
    };
}
