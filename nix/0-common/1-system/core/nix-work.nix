# Nix Work ###########################################################################################################################################
#
# Holds nix-daemon's builds and the X-Nix agent's evaluations in one slice beneath the services, so a deploy can slow a host but not starve it.
#

{ config, lib, ... }:
{
    config = lib.mkMerge [

        # Shared Ceiling #############################################################################################################################
        {
            systemd.slices.nix-work.sliceConfig = {
                MemoryHigh = lib.mkDefault "50%";
                MemoryMax = lib.mkDefault "60%";
                CPUWeight = lib.mkDefault 20;
                IOWeight = lib.mkDefault 20;
                ManagedOOMMemoryPressure = "kill";
            };

            systemd.services.nix-daemon.serviceConfig = {
                Slice = "nix-work.slice";
                # Builds inherit this, so a host-wide shortage kills a compiler before the editor or a terminal.
                OOMScoreAdjust = lib.mkDefault 500;
            };
        }

        (lib.mkIf config.services.x-nix-agent.enable {
            systemd.services.x-nix-agent.serviceConfig = {
                Slice = "nix-work.slice";
                OOMScoreAdjust = lib.mkDefault 500;
            };
        })

    ];
}
