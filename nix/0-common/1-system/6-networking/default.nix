# Networking
#
# Sets up default networking settings
#

{
    imports = [
        ./1-firewall.nix
        ./2-avahi.nix
    ];
}
