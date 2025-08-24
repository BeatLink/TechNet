{ config, ... }:
{
    # Loads the Wireguard private key from SOPS and sets the permissions to systemd-networkd
    sops.secrets.zfs_unlock_key = {
        sopsFile = ../../secrets.yaml;
    };
    services.zfsUnlock = {
        enable = true;
        pools = [
            "data-pool/storage"
            "root-pool"
        ];
        sshKey = config.sops.secrets.zfs_unlock_key.path;
        remoteHost = "10.100.100.2";
        remoteUser = "beatlink";
        remoteDatabasePath = "/Storage/Files/Documents/SecurityDatabase.kdbx";
    };
}
