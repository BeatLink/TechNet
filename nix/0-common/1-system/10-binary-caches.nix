# Binary caches
#
# Extra substituters, on top of cache.nixos.org.
#
# PinePhoneKernel publishes megi's kernel, which nothing else caches -- not
# nixpkgs, not cache.nixos.org, and mobile-nixos publishes no binaries at all. It
# is a full aarch64 kernel build otherwise: 16 minutes on that repository's
# native runners, roughly 13 hours here under binfmt.
#
# Applied network-wide rather than only on Thor, because the substituter has to
# be configured on whichever machine *builds* the closure, and Thor is built from
# Odin. A cache listed only in Thor's own configuration would be consulted by the
# running phone and ignored by the laptop compiling for it, which is precisely
# backwards.
#
# The module is imported from the flake rather than the URL and key being copied
# here, so a key rotation arrives with a flake update instead of silently
# breaking signature verification.
#
{ inputs, ... }:
{
    imports = [ inputs.pinephone-kernel.nixosModules.binaryCache ];
}
