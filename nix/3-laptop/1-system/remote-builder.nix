# Remote builder
#
# Off. aarch64 closures are built here under binfmt instead -- 6-software.nix
# registers the static qemu emulator that makes that work.
#
# Ragnarok held this job because it is the only native aarch64 machine on the
# network, and native beats emulated on comparable hardware. It is not
# comparable hardware: a Rock64 with 2GB of RAM against twelve cores and 32GB
# here. It is also a backup server, so a build competes with the one thing it
# exists to do -- and during its first Syncthing sync, with that much RAM, that
# is the whole machine.
#
# What makes emulation affordable is that the expensive part is never emulated.
# megi's kernel is roughly 13 hours under binfmt, measured, and it is not built
# at all: it arrives prebuilt from the signed cache configured in
# 0-common/1-system/10-binary-caches.nix and substitutes in about a minute. What
# is left to emulate is the out-of-tree modules built against that kernel -- ZFS
# being the one that matters, since Thor's root is on it -- plus whatever
# userland does not substitute from cache.nixos.org.
#
# Restoring it means putting back the buildMachines entry deleted here. The
# matching authorisation for Odin's host key is still in
# 1-backup-server/1-system/remote-builder.nix, so only this side has to change.
#
{
    nix.distributedBuilds = false;
}
