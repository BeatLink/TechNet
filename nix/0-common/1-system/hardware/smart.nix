# SMART Monitoring ###################################################################################################################################
#
# Runs smartd on every SMART-capable drive, with a short self-test nightly and a long one weekly, because a drive's own verdict stays PASSED through
# thousands of reallocated sectors while an extended test names the sector it could not read.
#

{ lib, ... }:
{
    services.smartd = {
        enable = lib.mkDefault true; # Thor's eMMC exposes no SMART, and smartd exits rather than start with zero devices registered

        # Temperatures suit flash, which is all the fleet runs bar one spinning disk that sets its own lower ceiling; a 0 difference drops change logging.
        defaults.monitored = "-a -S on -n standby,q -s (S/../.././02|L/../../6/03) -W 0,70,78";
    };
}
