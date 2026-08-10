# Security
#
# The TechNet root CA, SSH brute-force banning, the tang/clevis pair that unlocks the ZFS pools at boot, and the sops secret paths
#

{
    imports = [
        ./certificates.nix
        ./fail2ban.nix
        ./tang.nix
        ./clevis.nix
        ./secrets.nix
    ];
}
