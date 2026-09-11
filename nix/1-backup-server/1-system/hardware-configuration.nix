# Hardware Configuration #############################################################################################################################
#
# The Rock64's platform and the initrd drivers its storage and ethernet need.
#

{ lib, ... }:
{
    boot.initrd.availableKernelModules = [ "uas" ];

    # Force-loaded rather than left for udev to match: on demand the ethernet probed 50s into one boot, long after clevis had failed against an
    # unreachable tang and put a password prompt on a headless console. Listed in dependency order, innermost first.
    boot.initrd.kernelModules = [
        "stmmac"
        "stmmac_platform"
        "dwmac_rk"
    ];

    nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
