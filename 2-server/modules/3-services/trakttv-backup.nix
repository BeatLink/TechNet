{ pkgs, ... }: {
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
        path = [ pkgs.bash pkgs.gawk pkgs.curl pkgs.gnutar  ];
        script = ''
            cd /Storage/Services/TraktTv-Backup/trakt-backup; ${pkgs.bash}/bin/bash ./trakt-backup.sh -u BingeWatcherSupreme
        '';
        serviceConfig = {
            Type = "oneshot";
            User = "root";
        };
    };

    systemd.services."trakttv-auth" = {
        path = [ pkgs.bash pkgs.gawk pkgs.curl pkgs.gnutar  ];
        script = ''
            cd /Storage/Services/TraktTv-Backup/trakt-backup; ${pkgs.bash}/bin/bash ./trakt-auth.sh -u BingeWatcherSupreme
        '';
        serviceConfig = {
            Type = "oneshot";
            User = "root";
        };
    };
}

