# Impermanence #######################################################################################################################################
#
# Rolls the root and home datasets back to their blank snapshots in the initrd, so only persistence.nix and home.persistence entries survive a boot.
#

{
    pkgs,
    config,
    ...
}:
{
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
}
