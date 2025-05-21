{
    systemd.timers."trakttv-backup" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
            OnCalendar = "daily";
            Persistent = true; 
            Unit = "trakttv-backup.service";
        };
    };

    systemd.timers."trakttv-auth" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
            OnCalendar = "monthly";
            Persistent = true; 
            Unit = "trakttv-auth.service";
        };
    };

    systemd.services."trakttv-backup" = {
        script = ''
            cd /Storage/Services/TraktTv-Backup/trakt-backup; ./trakt-backup.sh -u BingeWatcherSupreme
        '';
        serviceConfig = {
            Type = "oneshot";
            User = "root";
        };
    };

    systemd.services."trakttv-auth" = {
        script = ''
            cd /Storage/Services/TraktTv-Backup/trakt-backup; ./trakt-auth.sh -u BingeWatcherSupreme
        '';
        serviceConfig = {
            Type = "oneshot";
            User = "root";
        };
    };
}

