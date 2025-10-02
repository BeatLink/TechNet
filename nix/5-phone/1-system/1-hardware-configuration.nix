{ pkgs, ... }:
{
    nixpkgs.hostPlatform = "aarch64-linux";

    hardware = {
        enableRedistributableFirmware = true;
    };
    boot.kernelModules = [
        "rtw88_8723cs" # Wifi Card
        "ax88179_178a" # USB Hub
    ];
}
