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
    # The ARC cap is confirmed on the first boot carrying it: c_max 512MB, ARC
    # size 516MB, available up from 429MB to 1756MB.
    #
    # Queue depths, in the same spirit as Heimdall's
    # 2-server/1-system/3-filesystem.nix but not the same numbers, because the
    # two are slow for different reasons. Heimdall's pool is a spinning mirror
    # and its 32 is about not drowning the disk in seeks. An SD card has no
    # seeks; what it has is almost no parallelism and painful write
    # amplification, so the depths go lower still and one extra knob appears.
    #
    # zfs_txg_timeout is that knob, and it is the SD-specific one: batching
    # transaction groups into fewer, larger commits means fewer erase-block
    # rewrites. 15s rather than the default 5s trades a longer window of
    # unwritten data for materially less churn on a card whose write endurance
    # is the thing that eventually kills it.
    #
    # Worth being clear that these are module parameters and therefore
    # **global** -- they apply to root-pool-Thor on the eMMC as well as
    # data-pool-Thor on the card. That is acceptable because the eMMC is also
    # not an SSD and also prefers shallow queues, but it does mean this is not
    # a per-pool tuning however much it reads like one.
    #
    # Unlike the ARC cap, these are a considered starting point rather than a
    # measured win. The thing to watch is whether Syncthing's initial hashing
    # still starves the session; if it does, the next lever is Syncthing's own
    # concurrency rather than pushing these lower.
    boot.extraModprobeConfig = ''
        options zfs zfs_arc_max=536870912

        options zfs zfs_vdev_max_active=4
        options zfs zfs_vdev_async_write_max_active=2
        options zfs zfs_vdev_async_read_max_active=2
        options zfs zfs_vdev_sync_read_min_active=4
        options zfs zfs_vdev_scrub_max_active=1
        options zfs zfs_txg_timeout=15
    '';

    boot.kernel.sysctl = {
        "vm.swappiness" = 100;
    };

    # ibus arrives via services.gnome.core-os-services, which the phosh module
    # turns on -- the same route as the tour and avahi. It is the largest CPU
    # consumer on the phone: ibus-extension held 63-73% across repeated samples
    # and had burned 48 seconds of CPU in the 82 it had been alive, which is a
    # busy loop rather than work.
    #
    # Nothing here uses it. Text entry on screen is stevia, and the keyboard
    # case's Pine layer is xkb. It was removed once before on the theory that it
    # was blocking the on-screen keyboard, which an A/B disproved -- the OSK
    # works either way -- and put back for that reason. The performance case is
    # separate and much stronger.
    i18n.inputMethod.enable = false;

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

    # The same argument as MemoryLow above, applied to whichever application is
    # in front rather than to the compositor -- see
    # 0-common/desktop/1-system/4-focus-boost.nix for how it finds it.
    #
    # On here and not on Odin because it is a response to 2972MB of RAM. A host
    # that is not reclaiming has nothing to protect anything from.
    technet.desktop.focusBoost.enable = true;

}
