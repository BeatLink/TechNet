# Swap ###############################################################################################################################################
#
# Zram compressed swap. There is no disk-backed swap: the root pool holds no swap zvol.
#

{ lib, ... }:
{
    config = lib.mkMerge [

        # Zram Swap ##################################################################################################################################
        {
            zramSwap.enable = true;
        }

        # Paging Behaviour ###########################################################################################################################
        {
            boot.kernel.sysctl."vm.page-cluster" = 0; # Readahead amortises a seek that zram does not have, so the extra pages are decompression for nothing
        }
    ];
}
