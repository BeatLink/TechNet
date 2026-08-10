# Security
#
# The TechNet root CA, SSH brute-force banning, the tang/clevis pair that unlocks the ZFS pools at boot, and the sops secret paths
#

{
    imports = [
        ./1-certificates.nix
        ./2-fail2ban.nix
        ./3-tang.nix
        ./4-clevis.nix
        ./5-secrets.nix
    ];
}
