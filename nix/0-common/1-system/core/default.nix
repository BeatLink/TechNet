# Core ###############################################################################################################################################
#
# Kernel and init tunables shared by every host: SysRq, resource reservations, the nix work slice, file limits, and panic handling.
#

{
    imports = [
        ./magic-sysrq.nix
        ./resource-protection.nix
        ./nix-work.nix
        ./file-limits.nix
        ./reboot-on-panic.nix
    ];
}
