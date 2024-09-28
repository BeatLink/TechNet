{ config, lib, pkgs, ... }: 
{
    sdImage.populateRootCommands = ''
        ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c \${config.system.build.toplevel} -d ./files/boot
    '';
    sdImage.populateFirmwareCommands = '''';
    sdImage.compressImage = false;
    sdImage.firmwarePartitionOffset = 50;
    sdImage.firmwareSize = 1;
    sdImage.postBuildCommands = ''
        dd if=\${pkgs.ubootRock64}/u-boot-rockchip.bin of=$img  conv=fsync,notrunc bs=512 seek=64
        sync
    '';
    fileSystems."/boot/firmware" = {};    
    swapDevices = [ ];                                                              # Disables Swap
}