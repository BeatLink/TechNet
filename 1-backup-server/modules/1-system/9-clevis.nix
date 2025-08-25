{ config, ... }:
{
    sops.secrets.clevis_key = {
        sopsFile = ../../secrets.yaml;
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

        systemd.services.wait-for-network-delay = {
            description = "Delay after network-online before ZFS import";
            after = [
                "systemd-networkd-wait-online.service"
            ];
            requires = [
                "systemd-networkd-wait-online.service"
            ];
            before = [
                "zfs-import-root-pool.service"
                "zfs-import-data-pool.service"
            ];
            wantedBy = [
                "zfs-import-root-pool.service"
                "zfs-import-data-pool.service"
            ];

            serviceConfig = {
                Type = "oneshot";
                ExecStart = [ "/bin/sleep 10" ];

            };
        };
    };
}
