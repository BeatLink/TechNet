# Builds Thor's Tow-Boot firmware with personal overrides layered on the
# rock64-pinephone-fixes branch. Not part of the NixOS closure; the image is
# installed out-of-band per docs/thor.md:
#
#   nix-build nix/5-phone/firmware.nix -A pine64-pinephoneA64
import /Storage/Files/Projects/Coding/Pinephone/Tow-Boot {
  configuration = { lib, ... }: {
    Tow-Boot.config = [
      (helpers: with helpers; {
        # Time to catch the boot menu: phone-ux force-sets 0 for the blind
        # UX, but with the panel lit the prompt is worth waiting on, so this
        # outranks that mkForce.
        BOOTDELAY = lib.mkOverride 40 (freeform "5");
      })
    ];
  };
}
