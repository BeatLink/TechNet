{ config, lib, pkgs, ... }: 
let 
    uboot = pkgs.ubootRock64v2.override {
        version = "2024.10";
        extraPatches = [./1-boot-fix-uboot.patch];
    };
in
{
    sdImage.populateRootCommands = ''
        ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c \${config.system.build.toplevel} -d ./files/boot
    '';
    sdImage.populateFirmwareCommands = '''';
    sdImage.compressImage = false;
    sdImage.firmwarePartitionOffset = 30;
    sdImage.firmwareSize = 1;
    sdImage.postBuildCommands = ''
        dd if=\${uboot}/idbloader.img of=$img  conv=fsync,notrunc bs=512 seek=64;
        dd if=\${uboot}}/u-boot.itb of=$img  conv=fsync,notrunc bs=512 seek=16384;
        sync;
    '';
    fileSystems."/boot/firmware" = {};
}