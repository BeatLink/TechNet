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

        # Build Ceiling ##############################################################################################################################
        # Every build runs inside nix-daemon, so this caps the compilers the session ceiling never sees, and a build that hits it fails on its own.
        #
        systemd.services.nix-daemon.serviceConfig = {
            MemoryHigh = "45%";
            MemoryMax = "55%";
            MemorySwapMax = "4G";
            # Builds inherit this, so a host-wide shortage kills a compiler before the editor or a terminal.
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
            freeMemThreshold = 5;
            freeMemKillThreshold = 3;
            # Desktop pop-ups would need systembus-notify, which the smartd setup keeps off; kills still land in the journal.
            enableNotifications = false;
            extraArgs = [
                "--ignore-root-user"
                "--ignore"
                "(^|/)(borg|borgmatic|syncthing|rsync|sshd|systemd.*)$"
            ];
        };
    };
}
