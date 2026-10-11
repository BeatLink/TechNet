# Memory Guard #######################################################################################################################################
#
# Stops one runaway desktop or agent process from exhausting RAM, which panic_on_oom would otherwise turn into a reboot of the whole laptop.
#

{
    config = {

        # User Session Ceiling #######################################################################################################################
        # A process that grows past this cgroup limit is killed alone, since only a host-wide out-of-memory triggers panic_on_oom.
        #
        systemd.slices.user.sliceConfig = {
            MemoryHigh = "78%";
            MemoryMax = "85%";
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
