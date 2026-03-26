# Persistence Subvolume Mounting ################################################################################################################
{ lib, ... }:
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

    systemd.services."systemd-tmpfiles-resetup" = {
        serviceConfig = {
            RemainAfterExit = lib.mkForce false;
        };
    };
}
