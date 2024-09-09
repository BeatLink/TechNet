{ config, lib, pkgs, modulesPath, ... }: {
        # Persistence -------------------------------------------------------------------------------------------------------------------------
    environment.persistence."/persistent" = {
        hideMounts = true;
        directories = [
            "/var/lib/nixos"
            "/var/log"
        ];
        files = [
            "/etc/machine-id"
        ];
    };
}