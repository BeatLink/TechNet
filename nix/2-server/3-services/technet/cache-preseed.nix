# Cache Preseed ######################################################################################################################################
#
# Builds the x86_64 host configurations every night so the day's first deploy substitutes instead of rebuilding.
#
# The bot bumps flake.lock at 06:00 UTC, which is 01:00 here, so 04:00 reads a lock that already holds the day's inputs.
#
{ config, pkgs, ... }:
{
    systemd.services.cache-preseed = {
        description = "Build the x86_64 host configurations so the Attic cache is warm";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        path = [
            config.nix.package
            pkgs.git
        ];

        # Ragnarok and Thor are aarch64 and are left out: Heimdall has no binfmt, and emulating a whole system closure costs hours for what an
        # afternoon deploy from Odin substitutes anyway.
        script = ''
            nix build --no-link --refresh --print-build-logs \
                github:BeatLink/TechNet#nixosConfigurations.Heimdall.config.system.build.toplevel \
                github:BeatLink/TechNet#nixosConfigurations.Odin.config.system.build.toplevel
        '';

        serviceConfig = {
            Type = "oneshot";

            # Four cores against 31GB that ZFS is already using most of, so the build is kept narrow enough to leave the services their memory.
            CPUQuota = "300%";
            Nice = 19;
            IOSchedulingClass = "idle";

            # Nothing downstream waits on this, so a broken input overnight stays a failed unit rather than a retry storm.
            Restart = "no";
        };
    };

    systemd.timers.cache-preseed = {
        description = "Nightly warm-up of the Attic cache";
        wantedBy = [ "timers.target" ];

        timerConfig = {
            OnCalendar = "*-*-* 04:00:00";
            Persistent = true; # A machine that was off at 04:00 still warms the cache once it is back
            RandomizedDelaySec = "15m";
        };
    };
}
