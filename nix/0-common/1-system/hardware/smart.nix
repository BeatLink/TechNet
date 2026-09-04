# SMART Monitoring ###################################################################################################################################
#
# Runs smartd against every SMART-capable drive, with a short self-test nightly and a long one weekly.
#
# The scheduled tests are the point. A drive's own `smartctl -H` verdict stays PASSED through thousands of reallocated sectors, so it reports a disk as
# healthy right up until it is not; an extended self-test reads every sector and names the LBA it could not.
#

{ lib, ... }:
{
    services.smartd = {
        enable = lib.mkDefault true; # Thor's eMMC exposes no SMART, and smartd exits rather than start with zero devices registered

        # -n standby,q lets a sleeping drive stay asleep, -S on keeps attributes across power cycles, and -s schedules the tests: short daily at 02:00,
        # long Saturdays at 03:00, which is ~3h on the server's laptop drives. -W reports a 4C swing and warns at 50C against a 55C ceiling: the pool
        # drives run at 39-45C, so a lower info threshold trips on an ordinary afternoon.
        defaults.monitored = "-a -S on -n standby,q -s (S/../.././02|L/../../6/03) -W 4,50,55";
    };
}
