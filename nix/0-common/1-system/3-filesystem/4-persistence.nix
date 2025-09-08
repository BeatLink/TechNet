# Persistence Subvolume Mounting ################################################################################################################
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
                parentDirectory = {
                    mode = "0755";
                };
            }
        ];
    };
}
