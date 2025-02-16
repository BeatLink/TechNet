{ lib, ... }:
{
    boot.initrd.availableKernelModules = [ "uas" "dwmac_rk" "stmmac" ];
    nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
