# Core ###############################################################################################################################################
#
# Kernel and init tunables shared by every host: SysRq, watcher and file-descriptor limits, zram swap, and panic handling.
#

{ lib, ... }:
{
    config = lib.mkMerge [

        # Magic SysRq ################################################################################################################################
        {
            boot.kernel.sysctl."kernel.sysrq" = 1;
        }

        # Filesystem Watcher Limit ###################################################################################################################
        {
            boot.kernel.sysctl."fs.inotify.max_user_watches" = "1048576"; # 128 times the default 8192
            systemd.settings.Manager = {
                DefaultLimitNOFILE = 65536;
            };
        }

        # Zram Swap ##################################################################################################################################
        {
            zramSwap.enable = true;
        }

        # Reboot On Panic ############################################################################################################################
        # OOM raises a panic, the panic reboots ten seconds later, and the kernelParam covers panics that hit before sysctls are applied.
        {
            boot = {
                kernelParams = [ "panic=10" ];
                kernel.sysctl = {
                    "kernel.panic" = 10;
                    "vm.panic_on_oom" = 1;
                };
            };
        }
    ];
}
