{ lib, ... }:
{
    boot.initrd.availableKernelModules = [ "uas" ];
    nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
