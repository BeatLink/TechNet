{
    # Filesystem Mounting ###########################################################################################################################
    boot = {
        supportedFilesystems = [ "zfs" ];
        initrd.supportedFilesystems = [ "zfs" ];
    };
    fileSystems = {
        "/".neededForBoot = true;
        "/boot".neededForBoot = true;
        "/nix".neededForBoot = true;
        "/persistent".neededForBoot = true;
        "/home".neededForBoot = true;
    };
}
