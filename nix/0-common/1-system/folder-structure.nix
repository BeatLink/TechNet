# Folder Structure ###################################################################################################################################
#
# Creates /Storage and the XDG directories under it, ages out /tmp and /var/tmp, and lists what survives the impermanence rollback.
# The root filesystem is wiped on every boot, so a path that is not persisted here is gone.
#

{ lib, ... }:
{
    config = lib.mkMerge [

        # Storage Directories ########################################################################################################################
        # The tmpfiles rules and the XDG pointers list the same six paths and have to agree, so they are kept together.
        # XDG points at the data pool rather than ~, so GTK's file chooser saves onto storage instead of the root filesystem that is rolled back each boot.
        {
            systemd.tmpfiles.settings."Storage" = {
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
            home-manager.users.beatlink.xdg.userDirs = {
                enable = true;
                desktop = "/Storage/Files/Desktop";
                documents = "/Storage/Files/Documents";
                download = "/Storage/Files/Downloads";
                music = "/Storage/Files/Music";
                pictures = "/Storage/Files/Pictures";
                videos = "/Storage/Files/Videos";
            };
        }

        # Temporary File Cleanup #####################################################################################################################
        # The q rules only set the ages; the timer is what actually walks them, so neither does anything useful without the other.
        {
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
            systemd.timers."systemd-tmpfiles-clean" = {
                wantedBy = [ "timers.target" ];
                timerConfig = {
                    OnCalendar = "daily";
                    Persistent = true;
                };
            };
        }

        # Tmpfiles Reapplication #####################################################################################################################
        {
            systemd.services."systemd-tmpfiles-resetup" = {
                serviceConfig = {
                    RemainAfterExit = lib.mkForce false; # Must stay false, or every tmpfiles rule in this file stops being reapplied on a switch
                };
            };
        }

        # Persistence Subvolume Mounting ############################################################################################################
        {
            environment.persistence."/persistent" = {
                hideMounts = true;
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
    ];
}
