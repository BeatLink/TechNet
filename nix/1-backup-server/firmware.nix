# Builds Ragnarok's Tow-Boot firmware with personal overrides layered on the
# rock64-pinephone-fixes branch. Not part of the NixOS closure; the image is
# written to the SD card out-of-band per docs/ragnarok.md:
#
#   nix-build nix/1-backup-server/firmware.nix -A pine64-rock64
{ src ? null }:
import /Storage/Files/Projects/Coding/Pinephone/Tow-Boot {
  inherit src;
  configuration = { lib, ... }: {
    Tow-Boot.config = [
      (helpers: with helpers; {
        # The board sits off site, so the firmware console is also reachable over the LAN it boots on.
        NETCONSOLE = yes;

        # This board boots its own disks, and the network targets cost a minute of TFTP timeouts before the menu appears.
        TOW_BOOT_NETWORK_BOOT = no;

        # Netconsole broadcasts on the LAN when ncip is unset, so any host there can listen; usb start comes first so the keyboard reaches the menu.
        # The DHCP call is only for that address: autoload keeps it from fetching a boot file and netretry keeps a silent LAN from stalling the boot.
        PREBOOT = lib.mkForce (freeform ''"usb start; setenv autoload no; setenv netretry no; if dhcp; then setenv stdout serial,vidconsole,nc; setenv stderr serial,vidconsole,nc; setenv stdin serial,usbkbd,nc; else setenv stdout serial,vidconsole; setenv stderr serial,vidconsole; fi"'');
      })
    ];
  };
}
