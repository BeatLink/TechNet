# Mount the Backup Drive ========================================================================================================================
{ config, lib, pkgs, ... }: {
    systemd.tmpfiles.rules = [
        "d /Storage 1770 borg borg"
    ];
    fileSystems."/Storage" = {
        device = "/dev/disk/by-uuid/4c6831d6-0d99-4d5a-805f-88d7878d6c4b";
        fsType = "ext4";
        options = ["defaults" "nofail" "discard"];
    };
}