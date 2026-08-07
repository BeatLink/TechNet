# Folder Structure ###################################################################################################################################
#
# Creates /Storage, ages out /tmp and /var/tmp, and lists what survives the impermanence rollback.
# The root filesystem is wiped on every boot, so a path that is not persisted here is gone.
#

{ lib, ... }: {

    # Managed Directories ############################################################################################################################
    systemd.tmpfiles.settings = {
        "Storage" = {
            "/Storage".d = {
                user = "beatlink";
                group = "beatlink";
                mode = "1777";
            };
        };
        "Cleanup" = {
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
                    age = "1d";
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
                    age = "7d";
                };
            };
        };
    };

    # Cleanup Schedule ###############################################################################################################################
    systemd = {
        services."systemd-tmpfiles-resetup" = {
            serviceConfig = {
                RemainAfterExit = lib.mkForce false; # Must stay false, or the rules above are never reapplied on a switch
            };
        };
        timers."systemd-tmpfiles-clean" = {
            wantedBy = [ "timers.target" ];
            timerConfig = {
                OnCalendar = "daily";
                Persistent = true;
            };
        };
    };

    # Persistence ####################################################################################################################################
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
}
