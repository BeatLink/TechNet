# Core ###############################################################################################################################################
#
# Kernel and init tunables shared by every host: SysRq, watcher and file-descriptor limits, and panic handling.
#

{
    imports = [
        ./magic-sysrq.nix
        ./file-limits.nix
        ./reboot-on-panic.nix
    ];
}
