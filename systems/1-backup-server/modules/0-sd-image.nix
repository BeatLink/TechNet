{ config, lib, pkgs, ... }: 
let 
    uboot = pkgs.ubootRock64v2.override {
        version = "2024.10";
        src = pkgs.fetchurl {
            url = "https://ftp.denx.de/pub/u-boot/u-boot-2024.10.tar.bz2";
            hash = "sha256-so2vSsF+QxVjYweL9RApdYQTf231D87ZsS3zT2GpL7A=";
        };
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
        dd if=\${uboot}/u-boot.itb of=$img  conv=fsync,notrunc bs=512 seek=16384;
        sync;
    '';
    fileSystems."/boot/firmware" = {};
}