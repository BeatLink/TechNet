{ config, lib, pkgs, ... }: 
{
    sdImage.populateRootCommands = ''
        ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c \${config.system.build.toplevel} -d ./files/boot
    '';
    sdImage.populateFirmwareCommands = '''';
    sdImage.compressImage = false;
    fileSystems = {
        "/" = {                                                             # Specifies the Root FS
            device = lib.mkForce "/dev/disk/by-label/ragnarok-root";
            fsType = "ext4";
        };
        "/boot/firmware" = {};
    };
    swapDevices = [ ];                                                              # Disables Swap
}