# Swap ###############################################################################################################################################
#
# Zswap in front of the encrypted swap partition disko declares on the SSD, in place of the fleet's zram. Zram is a fixed-size compressed block device
# that is itself the swap; zswap is a compressed cache ahead of a real device, so hot pages keep RAM and the shrinker writes the coldest out to disk.
#

{ lib, ... }:
{
    config = lib.mkMerge [

        # Zram Off ###################################################################################################################################
        {
            zramSwap.enable = lib.mkForce false; # nix/0-common/1-system/filesystems/swap.nix enables it fleet-wide; two compressed tiers for one purpose is one too many
        }

        # Zswap ######################################################################################################################################
        # No zswap.zpool: 6.18 has no such parameter, zsmalloc being the only allocator left, and it would log as unknown.
        {
            boot.kernelParams = [
                "zswap.enabled=1"
                "zswap.compressor=zstd"                                 # Built in; the 1.85x zram measured is the ratio that matters on 1.9GB, and lz4 is a module that trades it for CPU
                "zswap.max_pool_percent=25"                             # ~480MB of compressed pages; zram at 50% was itself the largest single consumer of memory on the box
                "zswap.shrinker_enabled=1"                              # Proactive writeback of the coldest pages to the partition, rather than only once the pool is full
            ];
        }

        # Paging Behaviour ###########################################################################################################################
        # vm.page-cluster=0 comes from the shared module and suits zswap for the same reason it suited zram.
        {
            boot.kernel.sysctl = {
                "vm.swappiness" = 100;
                "vm.watermark_scale_factor" = 200;                      # kswapd starts at 2% free rather than 0.1%, so reclaim runs ahead of allocation instead of stalling it
            };
        }
    ];
}
