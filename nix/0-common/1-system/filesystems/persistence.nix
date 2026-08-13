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
        ];
        files = [
            {
                file = "/etc/machine-id";
                parentDirectory.mode = "0755";
            }
        ];
    };
}
