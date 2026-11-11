# Builds Ragnarok's Tow-Boot firmware with personal overrides layered on the
# rock64-pinephone-fixes branch. Not part of the NixOS closure; the image is
# written to the SD card out-of-band per docs/ragnarok.md:
#
#   nix-build nix/1-backup-server/firmware.nix -A pine64-rock64
{
    src ? null,
}:
import /Storage/Files/Projects/Coding/Pinephone/Tow-Boot {
    inherit src;
    configuration = { lib, ... }: {
        Tow-Boot.config = [
            (
                helpers: with helpers; {
                    # This board boots its own disks, and the network targets cost a minute of TFTP timeouts before the menu appears.
                    TOW_BOOT_NETWORK_BOOT = no;

                    # USB is scanned before the prompt so a keyboard reaches the menu.
                    PREBOOT = lib.mkForce (freeform ''"usb start"'');
                }
            )
        ];
    };
}
