{ config, inputs, ... }:
{
    sops.secrets.clevis_key = {
        sopsFile = "${inputs.self}/secrets/1-backup-server.yaml";
    };

    boot.initrd = {
        clevis = {
            enable = true;
            useTang = true;
            devices = {
                "data-pool-${config.networking.hostName}/storage".secretFile = config.sops.secrets.clevis_key.path;
                "root-pool-${config.networking.hostName}".secretFile = config.sops.secrets.clevis_key.path;
            };
        };

        systemd.services = {
            "zfs-import-root-pool-${config.networking.hostName}".preStart = ''
                /bin/sleep 10
            '';

            "zfs-import-data-pool-${config.networking.hostName}".preStart = ''
                /bin/sleep 10
            '';
        };
    };
}
