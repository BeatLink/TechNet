# Impermanence #######################################################################################################################################
#
# Rolls the root and home datasets back to their blank snapshots in the initrd, so only persistence.nix and home.persistence entries survive a boot.
#
# Selected by technet.storage.backend = "zfs". The btrfs-luks equivalent lives in impermanence-btrfs.nix.
#

{
    pkgs,
    config,
    lib,
    ...
}:
{
    config = lib.mkIf (config.technet.storage.backend == "zfs") {
        boot.initrd.systemd.services.rollback = {
            description = "Rollback ZFS root subvolume to a pristine state";
            wantedBy = [ "initrd.target" ];
            after = [ "zfs-import-root-pool-${config.networking.hostName}.service" ];
            before = [ "sysroot.mount" ];
            path = with pkgs; [ zfs ];
            unitConfig.DefaultDependencies = "no";
            serviceConfig.Type = "oneshot";
            script = ''
                zfs rollback -Rf root-pool-${config.networking.hostName}/root@blank &&
                zfs rollback -Rf root-pool-${config.networking.hostName}/root/home@blank &&
                echo "Rollback Complete"
            '';
        };
    };
}
