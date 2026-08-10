# Networking
#
# Sets up default networking settings
#

{
    imports = [
        ./firewall.nix
        ./initrd-wireguard.nix
        ./wifi.nix
        ./vhosts.nix
    ];
}
