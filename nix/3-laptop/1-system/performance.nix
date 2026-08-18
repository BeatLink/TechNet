# Performance ########################################################################################################################################
#
# Memory tuning that keeps the ARC from competing with games for RAM.
#

{
    config = {

        # ARC Cap ####################################################################################################################################
        # Uncapped the ARC grows to most of RAM, and reclaiming it under a game's sudden allocations stalls the frame loop.
        boot.extraModprobeConfig = ''
            options zfs zfs_arc_max=4294967296
        '';
    };
}
