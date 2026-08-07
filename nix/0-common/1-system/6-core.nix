# Core #############################################################################################################################################
#
# Kernel and init tunables shared by every host: SysRq, watcher and file-descriptor limits, zram swap, and panic handling.

{
    # Magic SysRq ####################################################################################################################################
    boot.kernel.sysctl."kernel.sysrq" = 1;

    # Filesystem Watcher Limit #######################################################################################################################
    boot.kernel.sysctl."fs.inotify.max_user_watches" = "1048576"; # 128 times the default 8192
    systemd.settings.Manager = {
        DefaultLimitNOFILE = 65536;
    };

    # Memory Management ##############################################################################################################################
    zramSwap.enable = true;
    boot.kernel.sysctl."vm.panic_on_oom" = 1;

    # Reboot On Panic ################################################################################################################################
    boot.kernelParams = [ "panic=10" ];
    boot.kernel.sysctl."kernel.panic" = 10;
}
