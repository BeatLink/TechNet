{ config, lib, pkgs, ... }:
{
    hardware.nvidia = {
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        prime = {
            sync.enable = true;
        };
    };
}