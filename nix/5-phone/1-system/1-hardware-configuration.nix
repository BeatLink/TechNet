{ pkgs, ... }:
{
    nixpkgs.hostPlatform = "aarch64-linux";

    hardware = {
        enableRedistributableFirmware = true;
    };
    boot.kernelModules = [ "r8723bs" ];
}
