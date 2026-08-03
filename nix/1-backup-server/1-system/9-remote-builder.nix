# Remote builder access
#
# Odin offloads aarch64 builds here, since this is the only native aarch64 host.
# Its nix-daemon runs as root and connects as beatlink, using Odin's SSH host key
# as the client key -- so what is authorised here is Odin's host identity rather
# than a person's key. beatlink is already a trusted user, which is what lets the
# daemon hand off a build.
#
{
    users.users.beatlink.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINnDCoaEbXWh0rJshd2alkRQrGo+jsmKssXXMVbivl4p Odin"
    ];

    # What actually starves builds on this board is not parallelism, it is the
    # ZFS ARC. Measured idle, with 1911MB of RAM total:
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
    # zram from 0-common/1-system/4-core/3-memory-management.nix backstops the
    # rest: build memory is anonymous and compresses well, so a spill costs speed
    # rather than the build.
    nix.settings.cores = 3;
}
