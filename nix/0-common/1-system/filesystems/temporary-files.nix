# Temporary File Cleanup #############################################################################################################################
#
# Puts /tmp on a capped tmpfs so it empties at every boot, and prunes both temporary directories hourly.
#

{ lib, ... }:
{
    boot.tmp = {
        useTmpfs = true;
        tmpfsSize = lib.mkDefault "25%"; # A share of RAM rather than a fixed size, because the same value has to suit both the laptop and the phone
    };

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
            OnCalendar = "hourly"; # Hourly rather than daily, because /tmp now spends RAM and filling it is fatal rather than merely untidy
            Persistent = true;
        };
    };
}
