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
                "data-pool/storage".secretFile = config.sops.secrets.clevis_key.path;
                "root-pool".secretFile = config.sops.secrets.clevis_key.path;
            };
        };

        systemd.services = {
            zfs-import-root-pool.preStart = ''
                /bin/sleep 10
            '';

            zfs-import-data-pool.preStart = ''
                /bin/sleep 10
            '';
        };
    };
}
