# Networking
#
# Sets up default networking settings
#

{
    imports = [
        ./ddns.nix
        ./firewall.nix
        ./initrd-wireguard.nix
        ./network-manager.nix
    ];
}
