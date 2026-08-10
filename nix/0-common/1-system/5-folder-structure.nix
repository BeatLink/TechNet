# Folder Structure ###################################################################################################################################
#
# Creates /Storage and the XDG directories under it, ages out /tmp and /var/tmp, and lists what survives the impermanence rollback.
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
            "/Storage/Apps".d = {
                user = "root"; # Root-owned because impermanence creates each app's bind-mount source under it itself
                group = "root";
                mode = "0755";
            };
            "/Storage/Files".d = {
                user = "beatlink";
                group = "beatlink";
                mode = "0755";
            };
            "/Storage/Files/Desktop".d = {
                user = "beatlink";
                group = "beatlink";
                mode = "0755";
            };
            "/Storage/Files/Documents".d = {
                user = "beatlink";
                group = "beatlink";
                mode = "0755";
            };
            "/Storage/Files/Downloads".d = {
                user = "beatlink";
                group = "beatlink";
                mode = "0755";
            };
            "/Storage/Files/Music".d = {
                user = "beatlink";
                group = "beatlink";
                mode = "0755";
            };
            "/Storage/Files/Pictures".d = {
                user = "beatlink";
                group = "beatlink";
                mode = "0755";
            };
            "/Storage/Files/Videos".d = {
                user = "beatlink";
                group = "beatlink";
                mode = "0755";
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

    # XDG User Directories ###########################################################################################################################
    # Pointed at the data pool rather than ~, so GTK's file chooser saves onto storage instead of the root filesystem that is rolled back each boot.
    home-manager.users.beatlink = {
        xdg.userDirs = {
            enable = true;
            desktop = "/Storage/Files/Desktop";
            documents = "/Storage/Files/Documents";
            download = "/Storage/Files/Downloads";
            music = "/Storage/Files/Music";
            pictures = "/Storage/Files/Pictures";
            videos = "/Storage/Files/Videos";
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
