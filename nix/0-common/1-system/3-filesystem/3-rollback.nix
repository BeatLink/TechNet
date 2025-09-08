{ pkgs, ... }:
{
    # Impermanent Filesystem Rollback ###############################################################################################################
    boot.initrd.systemd.services.rollback = {
        description = "Rollback ZFS root subvolume to a pristine state";
        wantedBy = [ "initrd.target" ];
        after = [ "zfs-import-root-pool.service" ];
        before = [ "sysroot.mount" ];
        path = with pkgs; [ zfs ];
        unitConfig.DefaultDependencies = "no";
        serviceConfig.Type = "oneshot";
        script = ''
            zfs rollback -r  root-pool/root@blank && 
            zfs rollback -r  root-pool/home@blank && 
            echo "Rollback Complete"
        '';
    };
}
