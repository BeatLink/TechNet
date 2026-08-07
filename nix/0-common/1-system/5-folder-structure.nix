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

    systemd.tmpfiles.settings."Cleanup" = {
        "/tmp" = {
            d = {
                user = "root";
                group = "root";
                mode = "1777";
            };
            q = {
                user = "root";
                group = "root";
                mode = "1777";
                age = "10d";
            };
        };
        "/var/tmp" = {
            d = {
                user = "root";
                group = "root";
                mode = "1777";
            };
            q = {
                user = "root";
                group = "root";
                mode = "1777";
                age = "30d";
            };
        };
    };

    systemd.timers."systemd-tmpfiles-clean" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
        };
    };
}
