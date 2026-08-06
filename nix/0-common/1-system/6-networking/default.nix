# Networking
#
# Sets up default networking settings
#

{
    imports = [
        ./1-firewall.nix
        ./2-initrd-wireguard.nix
        ./3-wifi.nix
        ./4-vhosts.nix
    ];
}
