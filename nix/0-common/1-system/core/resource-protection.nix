# Resource Protection ################################################################################################################################
#
# Reserves memory and CPU along the login path, so a host under enough pressure to stop answering SSH can still be reached instead of power-cycled.
#

{ lib, ... }:
{
    config = lib.mkMerge [

        # Reserved Memory ############################################################################################################################
        # memory.min is a reclaim floor rather than an allocation, so it costs nothing until the host is short, and a parent must reserve what its children claim
        {
            systemd.slices.system.sliceConfig.MemoryMin = "192M";
            systemd.slices.user.sliceConfig.MemoryMin = "128M";
        }

        # Login Path #################################################################################################################################
        # logind and dbus are what turn an accepted connection into a session, so protecting sshd alone gets no further than a banner
        {
            # No OOMScoreAdjust here: sshd restores its saved value into every child, so the boost would follow each command run over SSH
            systemd.services.sshd.serviceConfig = {
                MemoryMin = "48M";
                CPUWeight = 1000;
                IOWeight = 1000;
            };

            systemd.services.systemd-logind.serviceConfig = {
                MemoryMin = "16M";
                CPUWeight = 500;
                OOMScoreAdjust = -900;
            };

            systemd.services.dbus.serviceConfig = {
                MemoryMin = "16M";
                CPUWeight = 500;
                OOMScoreAdjust = -900;
            };
        }

        # Automatic Kills ############################################################################################################################
        # Off rather than left at its default-on: an overloaded host Vigil can show beats a killer that can abort a backup or a sync mid-write
        {
            systemd.oomd.enable = false;
        }
    ];
}
