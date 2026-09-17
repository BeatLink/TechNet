# Performance ########################################################################################################################################
#
# Memory and clock tuning that keeps background work from competing with games.
#

{ pkgs, ... }:
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

        # Default Power Profile ######################################################################################################################
        # power-profiles-daemon owns both EPP and scaling_max_freq and rewrites them on every profile change, so a static sysfs write does not survive;
        # the profile is the only durable knob. power-saver holds the ceiling at the 3.3GHz base clock, which is boost off in all but name.
        #
        # Nothing here binds a game: selecting performance restores the full 4.28GHz ceiling and the performance governor, overriding this outright.
        # Upstream orders the daemon after multi-user.target, and a target is implicitly ordered after everything it wants, so asking for this from
        # multi-user.target is a cycle systemd breaks by dropping this job -- hooking it to the later graphical.target is what lets it run at all.
        systemd.services.default-power-profile = {
            description = "Select the power-saver profile at boot";
            wantedBy = [ "graphical.target" ];
            after = [
                "multi-user.target"
                "power-profiles-daemon.service"
            ];
            requires = [ "power-profiles-daemon.service" ];
            serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = "${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver";
            };
        };
    };
}
