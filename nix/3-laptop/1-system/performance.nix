# Performance ########################################################################################################################################
#
# Memory tuning that keeps the ARC from competing with games for RAM.
#

{
    config = {

        # ARC Cap ####################################################################################################################################
        # Uncapped the ARC grows to most of RAM, and reclaiming it under a game's sudden allocations stalls the frame loop.
        #
        # The dnode limit defaults to 10% of the cap, which this host's metadata working set exceeds roughly twofold, and ZFS then spins arc_prune at a
        # full core trying to evict below a limit the workload immediately refills. Raising it costs no extra ARC, so the cap above still holds.
        boot.extraModprobeConfig = ''
            options zfs zfs_arc_max=4294967296 zfs_arc_dnode_limit=1073741824
        '';
    };
}
