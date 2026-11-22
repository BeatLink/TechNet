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
        # X-Nix's evaluation and every build it starts, emulated ones included, share one cap and only use CPU the desktop leaves idle.
        #
        systemd.slices.nix-work.sliceConfig = {
            MemoryHigh = "30%";
            MemoryMax = "40%";
            MemorySwapMax = "4G";
            CPUWeight = "idle";
            IOWeight = 10;
            ManagedOOMSwap = "kill";
        };

        nix.daemonCPUSchedPolicy = "idle";
        nix.daemonIOSchedClass = "idle";

        systemd.services.x-nix-agent.serviceConfig = {
            CPUSchedulingPolicy = "idle";
            IOSchedulingClass = "idle";
        };

        # Pressure Kills #############################################################################################################################
        # Thrashing on zram never trips earlyoom's percentages, so stalls and swap use decide instead.
        #
        systemd.oomd = {
            enable = true;
            enableUserSlices = true;
            settings.OOM.SwapUsedLimit = "80%";
        };

        systemd.slices.user.sliceConfig.ManagedOOMSwap = "kill";

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
            # Reclaimable slab and a shrinking total keep this above 10% through a zram thrash, so oomd is the real guard.
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
