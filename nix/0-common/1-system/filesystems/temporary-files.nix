# Temporary File Cleanup #############################################################################################################################
#
# Puts /tmp on tmpfs so it empties at every boot, and ages out /var/tmp on a daily timer.
#

{ ... }:
{
    boot.tmp.useTmpfs = true; # Sized at half of RAM by default, so a build needing more than that must set TMPDIR elsewhere

    # The q rules only set the ages; the timer is what actually walks them, so neither does anything useful without the other.
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
