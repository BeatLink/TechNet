{ config, ... }:
{
    sops.secrets.clevis_key = {
        sopsFile = ../../secrets.yaml;
    };

    boot.initrd.clevis = {
        enable = true;
        useTang = true;
        devices = {
            "data-pool/storage".secretFile = config.sops.secrets.clevis_key.path;
            "root-pool".secretFile = config.sops.secrets.clevis_key.path;
        };
    };
}