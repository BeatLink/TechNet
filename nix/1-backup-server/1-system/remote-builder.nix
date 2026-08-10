# Remote builder access
#
# Dormant. Odin no longer offloads here -- it builds aarch64 locally under
# binfmt, for the reasons in 3-laptop/1-system/remote-builder.nix, chiefly
# that this is a 2GB board whose actual job is receiving backups. The
# authorisation is kept so that turning it back on is a one-file change there.
#
# What is authorised is Odin's host identity rather than a person's key: its
# nix-daemon runs as root and connects as beatlink using Odin's SSH host key as
# the client key. beatlink is already a trusted user, which is what lets the
# daemon hand off a build.
#
{
    users.users.beatlink.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINnDCoaEbXWh0rJshd2alkRQrGo+jsmKssXXMVbivl4p Odin"
    ];

    # The ARC cap outlives the build role and is the reason it stays in this
    # file. It was found while chasing builds, but what it protects is any burst
    # of allocation on a 2GB board -- Syncthing hashing a first sync now, rather
    # than compilers. Measured idle, with 1911MB of RAM total:
    #
    #   ARC size 1209MB, available 125MB       <- default, c_max ~= half of RAM
    #   ARC size  424MB, available 1056MB      <- capped at 512MB
    #
    # ARC is reclaimable in principle, but it gives memory back more slowly than
    # a burst of compilers takes it, so the headroom has to exist up front. 512MB
    # is still a useful cache for a box that mostly streams backups, where the
    # working set is written once and not re-read.
    #
    # Set as a module parameter rather than at runtime so it survives a reboot;
    # zfs is loaded in the initrd, so this has to be in modprobe config to be
    # read at the right time.
    boot.extraModprobeConfig = "options zfs zfs_arc_max=536870912";

    # With the ARC capped there is roughly 1GB free, so the compilers are the
    # constraint again rather than the cache. Three rather than four leaves room
    # for the occasional heavy translation unit and the vmlinux link without
    # giving up a quarter of the throughput -- which matters on 1.3GHz A53 cores,
    # where a kernel build is measured in hours either way.
    #
    # zram from 0-common/1-system/4-core.nix backstops the
    # rest: build memory is anonymous and compresses well, so a spill costs speed
    # rather than the build.
    nix.settings.cores = 3;
}
