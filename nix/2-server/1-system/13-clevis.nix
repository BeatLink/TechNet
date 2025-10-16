{ config, inputs, ... }:
{
    sops.secrets.clevis_key = {
        sopsFile = "${inputs.self}/secrets/2-server.yaml";
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
                /bin/sleep 30
            '';

            "zfs-import-data-pool-${config.networking.hostName}".preStart = ''
                /bin/sleep 30
            '';
        };
    };
}
