# Swap ###############################################################################################################################################
#
# Zswap in front of the swapfile disko declares on the SSD's @swap subvolume, in place of the fleet's zram. Zram is a fixed-size compressed block
# device that is itself the swap; zswap is a compressed cache ahead of a real device, so hot pages keep RAM and the shrinker writes the coldest out to
# disk.
#

{ lib, ... }:
{
    config = lib.mkMerge [

        # Zram Off ###################################################################################################################################
        {
            zramSwap.enable = lib.mkForce false; # nix/0-common/1-system/filesystems/swap.nix enables it fleet-wide; two compressed tiers for one purpose is one too many
        }

        # Zswap ######################################################################################################################################
        {
            boot.kernelParams = [
                "zswap.enabled=1"
                "zswap.compressor=zstd" # Built in, and it compresses better than lz4, which is a module that trades ratio for CPU
                "zswap.max_pool_percent=25" # A quarter of RAM at most for compressed pages, so the cache cannot become the largest consumer of memory itself
                "zswap.shrinker_enabled=1" # Proactive writeback of the coldest pages to the partition, rather than only once the pool is full
            ];
        }

        # Paging Behaviour ###########################################################################################################################
        {
            boot.kernel.sysctl = {
                "vm.swappiness" = 100;
                "vm.watermark_scale_factor" = 200;
            };
        }
    ];
}
