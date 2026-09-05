# Persisted Paths ####################################################################################################################################
#
# The system paths bind-mounted out of /persistent so they survive a wiped root.
#

{ ... }:
{
    environment.persistence."/persistent" = {
        hideMounts = true;
        directories = [
            "/var/lib/nixos"
            "/var/log"
            "/var/cache/vigil-borg"                                     # Borg's chunks cache for Vigil-triggered backups, which is expensive enough to rebuild that it should outlive the root wipe
            "/var/lib/systemd/timers"                                   # Persistent= timer stamps; without them every reboot counts as a missed run and nixos-upgrade fires at boot
            "/var/lib/systemd/timesync"                                 # timesyncd's clock file, whose mtime is the floor the clock starts from on a host whose RTC did not keep time
        ];
        files = [
            {
                file = "/etc/machine-id";
                parentDirectory.mode = "0755";
            }
        ];
    };
}
