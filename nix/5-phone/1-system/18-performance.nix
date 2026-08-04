# Performance
#
# Things done specifically because this is a 2972MB, 1.15GHz A53 phone rather
# than a laptop or a server. Measured, not guessed -- each note says what was
# observed.
#
# The ZFS ARC is by far the largest single consumer on this phone. Measured on a
# 2972MB device, 31 minutes after boot, with nothing but phosh, Firefox and a
# waydroid init running:
#
#   ARC size 1622MB, c_max 1948MB, available 429MB
#
# That is more than half of RAM held as filesystem cache on a device whose whole
# problem is not having any. The ARC is reclaimable in principle, but it gives
# memory back more slowly than a burst of allocation takes it, so the headroom
# has to exist up front -- the same finding as Ragnarok's
# 1-backup-server/1-system/9-remote-builder.nix, which caps it for the same
# reason on a smaller board.
#
# 512MB here as well. This is a phone: the working set is a handful of apps and
# their libraries, already warm in the page cache, and Waydroid wants 1-1.5GB of
# its own the moment an Android app starts.
#
# A module parameter rather than a runtime write, because zfs is loaded in the
# initrd and anything set later applies after the ARC has already grown.
#
# vm.swappiness is raised from the default 60. Swap here is zram -- compressed
# pages in RAM, not a disk -- so paging out cold anonymous memory costs CPU
# rather than an SD card round trip, and on four cores that is the cheaper of
# the two. The 16GB dm-0 swap on the encrypted zvol stays at priority -2 as the
# overflow behind it.
#
{
    boot.extraModprobeConfig = "options zfs zfs_arc_max=536870912";

    boot.kernel.sysctl = {
        "vm.swappiness" = 100;
    };

    # The compositor should be the last thing to stall. phoc runs as a child of
    # phosh.service, so it inherits all of this and needs no unit of its own.
    #
    # Worth being clear about what each part actually fixes, because they are
    # not the same freeze:
    #
    #   Nice, CPUWeight, IOWeight  help when something is competing for CPU or
    #                              the card -- Syncthing hashing, a Waydroid
    #                              container, a nix copy. Real here, and what
    #                              these are for.
    #
    #   MemoryMin, MemoryLow       help when the stall is memory reclaim, which
    #                              priority cannot touch at all: a high-priority
    #                              process waits on a page fault exactly as long
    #                              as a low-priority one. These reserve memory
    #                              the kernel will not reclaim from the session.
    #
    # Nice = -5 rather than -10. Four 1.15GHz cores do not have the headroom for
    # the compositor to monopolise them, and starving everything else shows up
    # as the session being responsive while nothing it launches ever starts.
    #
    # Negative Nice works despite User = beatlink because systemd applies it in
    # the child before dropping privileges.
    #
    # MemoryMin is a hard floor and MemoryLow best-effort above it. 192M against
    # 2972M total is deliberately modest -- phoc and phosh together sit around
    # 160M measured -- because a floor the system cannot satisfy trades a freeze
    # for an OOM kill.
    systemd.services.phosh.serviceConfig = {
        Nice = -5;
        CPUWeight = 1000;
        IOWeight = 1000;
        OOMScoreAdjust = -500;
        MemoryMin = "192M";
        MemoryLow = "512M";
    };

}
