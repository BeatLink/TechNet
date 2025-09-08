{
    # Filesystem Watcher Limit
    #
    # Increase number of open files for apps (Steam, syncthing, etc)
    #
    boot.kernel.sysctl."fs.inotify.max_user_watches" = "1048576"; # 128 times the default 8192
    systemd.settings.Manager = {
        DefaultLimitNOFILE = 65536;
    };



}
