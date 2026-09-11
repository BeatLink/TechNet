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
        # This board boots its own disks, and the PXE and DHCP targets cost a minute of TFTP timeouts before failing.
        # Netconsole broadcasts on the LAN when ncip is unset, so any host there can listen; usb start comes first so the keyboard reaches the menu.
        # GPIO A2 gates VBUS on every port, and cycling it revives the root SSD's bridge when it comes up wedged; only when the disk is missing, since a healthy bridge is better left alone.
        PREBOOT = lib.mkForce (freeform ''"usb start; if usb dev 0; then echo; else gpio set A2; sleep 2; gpio clear A2; sleep 2; usb reset; fi; setenv boot_targets mmc0 mmc1 usb0; setenv autoload no; setenv netretry no; if dhcp; then setenv stdout serial,vidconsole,nc; setenv stderr serial,vidconsole,nc; setenv stdin serial,usbkbd,nc; else setenv stdout serial,vidconsole; setenv stderr serial,vidconsole; fi"'');
      })
    ];
  };
}
