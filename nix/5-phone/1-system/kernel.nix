# Kernel
#
# megi's tree rather than mainline, from https://github.com/BeatLink/PinePhoneKernel
#
# Mainline cannot charge this phone. The pack has a 3k NTC, the AXP803 powers up
# with its over-temperature threshold tuned for a 10k one, and axp20x_battery
# never reprograms it -- its only temperature handling is in
# axp717_set_battery_info(), for a different PMIC. So a healthy battery above
# ~14C reads as over temperature and the charger refuses, which presents exactly
# as a dead cell. megi's tree sets the threshold correctly. See docs/thor.md.
#
# It also carries the drivers mainline does not: ANX7688 (USB-C role detection,
# and with it USB-PD and DisplayPort alt mode), RTL8723CS (WiFi), IP5xxx (the
# keyboard case battery), and the PinePhone device trees including the keyboard
# accessory.
#
# Taken as a prebuilt package rather than defined here. That flake's CI builds it
# on GitHub's native aarch64 runners and publishes a signed binary cache, which
# is the difference between 16 minutes there and roughly 13 hours locally under
# binfmt -- measured, not estimated. Substituting it takes about a minute.
#
# The kernel deliberately comes from that flake's nixpkgs rather than ours. A
# kernel built against a slightly different nixpkgs than userland is fine; making
# it follow ours would change the stdenv, change the derivation, and lose the
# cache entirely.
#
# That cache is published as a release asset rather than served, so it is not a
# substituter anyone can point at. Heimdall unpacks it once and re-serves it from
# Attic, which is where every host including Odin substitutes the kernel from
# while building Thor's closure. See
# nix/2-server/3-services/technet/pinephone-kernel-mirror.nix.
#
# Out-of-tree modules are still built locally against it. ZFS is the one that
# matters here, since Thor's root is on it -- linuxPackagesFor builds that with
# this system's pkgs, so it is not cached and takes a while under emulation.
#
{ pkgs, inputs, ... }:
{
    boot.kernelPackages = pkgs.linuxPackagesFor inputs.pinephone-kernel.packages.aarch64-linux.linux-pinephone-megi;
}
