{ lib, ... }:
{
    # Automatic cleanup for transient directories
    systemd.tmpfiles.rules = [
        "d /tmp 1777 root root -"
        "d /var/tmp 1777 root root -"
        "q /tmp 1777 root root 10d"
        "q /var/tmp 1777 root root 30d"
    ];

    systemd.timers."systemd-tmpfiles-clean" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
        };
    };
}
