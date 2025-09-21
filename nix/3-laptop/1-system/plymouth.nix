{
    boot = {
        initrd.verbose = false;
        # Enable "Silent Boot"
        consoleLogLevel = 0;
        kernelParams = [
            "quiet"
            "splash"
            "boot.shell_on_fail"
            "loglevel=3"
            "rd.systemd.show_status=false"
            "rd.udev.log_level=3"
            "udev.log_priority=3"
        ];
    };
}