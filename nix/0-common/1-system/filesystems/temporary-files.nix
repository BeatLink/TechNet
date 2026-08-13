# Temporary File Cleanup #############################################################################################################################
#
# Keeps /tmp on the root dataset, which impermanence empties at every boot, and prunes both temporary directories hourly.
#

{ ... }:
{
    boot.tmp.useTmpfs = false; # On disk rather than in RAM, because the boot rollback already empties /tmp and a large build there would otherwise cost memory the machine needs

    # q both creates the directory and sets the age, and must be the only rule for a path -- a d rule alongside it wins as the first line and tmpfiles drops the aged one as a duplicate, disabling cleanup entirely.
    systemd.tmpfiles.settings."Cleanup" = {
        "/tmp".q = {
            user = "root";
            group = "root";
            mode = "1777";
            age = "1d";
        };
        "/var/tmp".q = {
            user = "root";
            group = "root";
            mode = "1777";
            age = "7d";
        };
    };

    systemd.timers."systemd-tmpfiles-clean" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
            OnCalendar = "hourly"; # Hourly rather than daily, so the ages set above take effect promptly instead of up to a day late
            Persistent = true;
        };
    };
}
