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
        ];
        files = [
            {
                file = "/etc/machine-id";
                parentDirectory.mode = "0755";
            }
        ];
    };
}
