# Networking
#
# Sets up default networking settings
#

{
    imports = [
        ./firewall.nix
        ./initrd-wireguard.nix
        ./network-manager.nix
    ];
}
