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

        # Recording by hand catches what was running when it was run. A trace of
        # a launch with everything else closed found the recorded set all but
        # complete -- 0.36 MiB of library pages faulted in that it did not have
        # -- but that is one application on one day, and every profile here is
        # invalidated by the next nixpkgs bump.
        #
        # Sampling everything costs 3.1s per pass on this phone, so 300s is
        # about 1% of one core, and a single sample of everything running
        # captured 212 MiB against the 243 MiB assembled here app by app.
        # Retention is deliberately far longer than the sampling interval. A
        # preloader whose memory is shorter than a session defeats itself: an
        # application opened after lunch would have aged out by then and be
        # back to faulting off the eMMC.
        #
        # A page is kept for a day after the last sample that saw it, and
        # carries a count of how many samples have, so the lock budget spends
        # itself on what is actually used.
        watch = {
            enable = true;
            interval = 300;
            retention = 86400;

            # Reacting to a launch matters more here than the interval does.
            # Waiting up to five minutes to notice an application started means
            # the one thing not covered is the thing just opened -- and on this
            # phone that costs a cold read off the card. 20s is long enough for
            # webkit to finish mapping and the window to be up.
            settle = 20;
            minGap = 60;
        };

        profiles = {
            # The cache is here because a trace said so, not because it looked
            # likely. Launching with everything else closed and the lock held,
            # the only pages faulted in that no profile covered were 6.4 MiB of
            # WebKitCache blobs -- against 0.36 MiB of library pages, so the
            # recorded ranges are otherwise complete.
            #
            # It is on the eMMC rather than the card, and only 6.4 MiB of its
            # 130 MiB was touched, so this is the cheap end of the problem. The
            # SD-backed directories below are the expensive one.
            epiphany.dirs = [
                "/home/beatlink/.local/share/epiphany"
                "/home/beatlink/.config/epiphany"
                "/home/beatlink/.cache/epiphany"
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
