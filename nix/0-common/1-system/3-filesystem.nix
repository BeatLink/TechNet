# Filesystem ###########################################################################################################################
{
    # ZFS Support
    boot = {
        supportedFilesystems = [ "zfs" ];
        initrd.supportedFilesystems = [ "zfs" ];
        zfs.forceImportRoot = false;
    };

    # Filesystem Maintenance. TRIM, scrubbing, etc
    services = {
        fstrim.enable = true;
        zfs = {
            trim.enable = true;
            autoScrub.enable = true;
        };
    };

}
