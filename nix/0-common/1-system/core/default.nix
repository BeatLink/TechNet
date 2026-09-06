# Core ###############################################################################################################################################
#
# Kernel and init tunables shared by every host: SysRq, login-path resource reservations, watcher and file-descriptor limits, and panic handling.
#

{
    imports = [
        ./magic-sysrq.nix
        ./resource-protection.nix
        ./file-limits.nix
        ./reboot-on-panic.nix
    ];
}
