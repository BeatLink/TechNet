# Keeping what applications need at startup resident.
#
# Replaces the app-preload module that used to live here; the tooling moved to
# its own repository, /Storage/Files/Projects/Coding/Prewarm.
#
# Two different problems on this phone, and they want different mechanisms.
#
# Libraries are recorded rather than declared. `prewarm record` captures the
# pages a warm process actually faulted in, and for a shared library that is a
# small fraction of the file -- 449 MiB of webkit, LLVM, mesa and gtk against
# 109 MiB touched. Declaring those as whole files would more than quadruple what
# every warm pass reads, for pages nothing ever executes.
#
# Application profiles are declared, because recording cannot see them: they are
# read rather than mapped, so nothing appears in pagemap. They are also the
# larger win. Every app's persistence is on the SD card -- /Storage is
# data-pool-Thor on mmcblk0, and only /, /nix, /home and /persistent are on the
# eMMC -- and the card measured 3028us per file against the eMMC's 1288us.
# Warming Home Assistant's 55 MiB profile took a cold start from 11.5s to 4.5s.
#
{ inputs, ... }:
{
    imports = [ inputs.prewarm.nixosModules.default ];

    services.prewarm = {
        enable = true;

        # beatlink is not in `users`, so the state directory is owned by the
        # user's own group or recording needs root.
        group = "beatlink";

        # Above the recorded set with room to grow. Recording with no size floor
        # -- the default now, where the old module skipped anything under 2 MiB
        # and locked those whole instead -- took Epiphany alone from 92 MiB to
        # 161 MiB, and the other four profiles are still on the old floor.
        #
        # The cap drops whatever sorts last by path rather than whatever is
        # least useful, so overrunning it loses arbitrary pages. Worth staying
        # ahead of: RAM is not the constraint on this phone, measured 1238 MiB
        # available with everything above already locked.
        maxLocked = 384 * 1024 * 1024;

        profiles = {
            epiphany.dirs = [
                "/home/beatlink/.local/share/epiphany"
                "/home/beatlink/.config/epiphany"
            ];

            weblaunch.dirs = [
                "/home/beatlink/.local/share/weblaunch"
            ];
        };
    };

    # Recorded profiles are expensive to produce -- the recording has to happen
    # while the app is warm -- so they survive the rollback of /.
    environment.persistence."/persistent".directories = [ "/var/lib/prewarm" ];
}
