{ config, lib, pkgs, ... }: 
{
    sdImage.populateRootCommands = ''
        ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c \${config.system.build.toplevel} -d ./files/boot
    '';
    sdImage.populateFirmwareCommands = '''';
    sdImage.compressImage = false;
    sdImage.firmwarePartitionOffset = 30;
    sdImage.firmwareSize = 1;
    sdImage.postBuildCommands = ''
        dd if=\${pkgs.ubootRock64v2.override {extraPatches = [./1-boot-fix-uboot-initrd.patch];}}/idbloader.img of=$img  conv=fsync,notrunc bs=512 seek=64;
        dd if=\${pkgs.ubootRock64v2.override {extraPatches = [./1-boot-fix-uboot-initrd.patch];}}/u-boot.itb of=$img  conv=fsync,notrunc bs=512 seek=16384;
        sync;
    '';
    fileSystems."/boot/firmware" = {};
}