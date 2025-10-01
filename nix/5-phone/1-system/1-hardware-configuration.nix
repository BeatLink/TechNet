{pkgs, ...}:{
    nixpkgs.hostPlatform = "aarch64-linux";
    hardware.firmware = with pkgs; [ linux-firmware ];
    boot.kernelModules = [ "rtw8723cs" ];
}
