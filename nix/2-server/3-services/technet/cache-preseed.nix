# Cache Preseed ######################################################################################################################################
#
# Builds every host configuration each night so the day's first deploy substitutes instead of rebuilding.
#
# The bot bumps flake.lock at 06:00 UTC, which is 01:00 here, so 04:00 reads a lock that already holds the day's inputs.
#
{
    config,
    lib,
    pkgs,
    ...
}:
{
    config = lib.mkMerge [

        # Emulation ##################################################################################################################################
        # The aarch64 hosts are the ones whose rebuilds are measured in hours, and the two that cannot warm the cache for themselves: Thor and
        # Ragnarok build slowly, and a deploy from Odin only reaches the cache when someone is at the laptop. Emulating them here is what puts
        # an aarch64 path in the cache before the phone's own weekly auto-upgrade goes looking for it.
        {
            boot.binfmt = {
                emulatedSystems = [ "aarch64-linux" ];
                preferStaticEmulators = true; # The static interpreter is already in the upstream cache; the full qemu closure is a larger pull
            };
        }

        # Nightly Build ##############################################################################################################################
        {
            systemd.services.cache-preseed = {
                description = "Build every host configuration so the Attic cache is warm";
                after = [ "network-online.target" ];
                wants = [ "network-online.target" ];

                path = [
                    config.nix.package
                    pkgs.git
                ];

                # x86_64 first: those two build natively and are what a morning deploy asks for, so a slow emulated host cannot delay them.
                script = ''
                    nix build --no-link --refresh --print-build-logs \
                        github:BeatLink/TechNet#nixosConfigurations.Heimdall.config.system.build.toplevel \
                        github:BeatLink/TechNet#nixosConfigurations.Odin.config.system.build.toplevel

                    nix build --no-link --refresh --print-build-logs \
                        github:BeatLink/TechNet#nixosConfigurations.Thor.config.system.build.toplevel \
                        github:BeatLink/TechNet#nixosConfigurations.Ragnarok.config.system.build.toplevel
                '';

                serviceConfig = {
                    Type = "oneshot";

                    # Four cores against 31GB that ZFS is already using most of, so the build is kept narrow enough to leave the services their memory.
                    CPUQuota = "300%";
                    Nice = 19;
                    IOSchedulingClass = "idle";

                    # An emulated build can still be running at the next bump, and a run that overruns its own day is a failure worth seeing.
                    TimeoutStartSec = "20h";

                    # Nothing downstream waits on this, so a broken input overnight stays a failed unit rather than a retry storm.
                    Restart = "no";
                };
            };
        }

        # Schedule ###################################################################################################################################
        {
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
    ];
}
