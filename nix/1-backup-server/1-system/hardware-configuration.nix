# Hardware Configuration #############################################################################################################################
#
# The Rock64's platform and the initrd drivers its storage and ethernet need.
#

{ lib, ... }:
{
    boot.initrd.availableKernelModules = [
        "uas"
        "dwmac_rk" # Ethernet in the initrd, so remote unlock has a link to run over
        "stmmac"
    ];
    nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
