{ pkgs, ... }:
{
    nixpkgs.hostPlatform = "aarch64-linux";

    hardware = {
        enableRedistributableFirmware = true;
    };
    boot.kernelModules = [ "rtl8723bs-firmware" ];
}
