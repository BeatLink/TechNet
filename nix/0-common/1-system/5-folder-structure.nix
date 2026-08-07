{ lib, ... }: {

    
    systemd.tmpfiles.settings."Storage"."/Storage".d = {
        user = "beatlink";
        group = "beatlink";
        mode = "1777";
    };

    systemd.services."systemd-tmpfiles-resetup" = {
        serviceConfig = {
            RemainAfterExit = lib.mkForce false;
        };
    };

    environment.persistence."/persistent" = {
        directories = [
            "/var/lib/nixos"
            "/var/log"
        ];
        files = [
            {
                file = "/etc/machine-id";
                parentDirectory.mode = "0755";
            }
        ];
    };

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
