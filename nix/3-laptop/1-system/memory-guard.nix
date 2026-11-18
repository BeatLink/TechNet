# Memory Guard #######################################################################################################################################
#
# Stops one runaway desktop, agent or build process from exhausting RAM, so the kernel never has to pick a victim from the whole laptop.
#

{
    config = {

        # User Session Ceiling #######################################################################################################################
        # A process that grows past this cgroup limit is killed alone, and the swap cap stops it filling swap before the limit is ever reached.
        #
        systemd.slices.user.sliceConfig = {
            MemoryHigh = "78%";
            MemoryMax = "85%";
            MemorySwapMax = "8G";
        };

        # Nix Work Ceiling ###########################################################################################################################
        # X-Nix's evaluation and every build it starts share one cap, so together they can never take more than this from the desktop.
        #
        systemd.slices.nix-work.sliceConfig = {
            MemoryHigh = "30%";
            MemoryMax = "40%";
            MemorySwapMax = "4G";
        };

        systemd.services.nix-daemon.serviceConfig = {
            Slice = "nix-work.slice";
            # Builds inherit this, so a host-wide shortage kills a compiler before the editor or a terminal.
            OOMScoreAdjust = 500;
        };

        systemd.services.x-nix-agent.serviceConfig = {
            Slice = "nix-work.slice";
            OOMScoreAdjust = 500;
        };

        # Build Width ################################################################################################################################
        # Three jobs of four threads fill the twelve threads once, rather than twelve jobs each spawning a compiler per thread.
        #
        nix.settings = {
            max-jobs = 3;
            cores = 4;
        };

        # Early User Kills ###########################################################################################################################
        # A backstop for growth outside the user slice; it never touches root's processes or the backup and sync tools, which may not stop mid-write.
        #
        services.earlyoom = {
            enable = true;
            # Below 10 the kernel's own OOM killer fires first, because zram and the ZFS ARC hide from earlyoom's total.
            freeMemThreshold = 10;
            freeMemKillThreshold = 5;
            # Swap is zram, which runs out of RAM to compress into long before it reads as full, so memory alone decides.
            freeSwapThreshold = 100;
            freeSwapKillThreshold = 100;
            # Desktop pop-ups would need systembus-notify, which the smartd setup keeps off; kills still land in the journal.
            enableNotifications = false;
            extraArgs = [
                "--ignore-root-user"
                "--ignore"
                "(^|/)(borg|syncthing|rsync|sshd|systemd.*)$"
                # Without this, Chromium's raised score makes every editor window die before a leaking agent or compiler.
                "--prefer"
                "(^|/)(claude|nix|rustc|ld|cc1plus)$"
            ];
        };
    };
}
