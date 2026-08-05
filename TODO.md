# TODO

Outstanding work, most blocking first. Background for the Thor items is in [docs/thor.md](docs/thor.md).

## In flight

Built and waiting to deploy, most of it unverified on hardware.

* Deploy Ragnarok: SMR queue depths and Syncthing CPU quota
* Syncthing GUI password and reverse proxy, all hosts

## Ragnarok

* Setup ZFS Optimizations
* Setup Syncthing Optimizations
* autotrim is a no-op behind the SATA-to-USB bridge
* Data disk is SMR, so write stalls have a floor

## Odin

* Backups only cover /Storage/System, which is 7.5K
* aarch64 now builds here under binfmt, not on Ragnarok

## Thor

* Raise the charging current the keyboard case supplies to the phone. Its
  default is conservative enough that heavy work outruns it and the battery
  falls even while attached. The KB151 firmware exposes charger control over I2C, so this is a setting
  to drive from the host rather than a hardware limit. Charge the phone at maximum safe charging rate until the phones battery reaches 75% then hold between 75 and 80%. if it drops below.
* Fix fwupdate
* [www.freedesktop.org/wiki/Specifications/desktop-bookmark-spec/?__goaway_challenge=meta-refresh&amp;__goaway_id=df93c11d9ee5b312d692e413745c8585&amp;__goaway_referer=https%3A%2F%2Fduckduckgo.com%2F](https://www.freedesktop.org/wiki/Specifications/desktop-bookmark-spec/?__goaway_challenge=meta-refresh&__goaway_id=df93c11d9ee5b312d692e413745c8585&__goaway_referer=https%3A%2F%2Fduckduckgo.com%2F)
* Setup Waydroid
* Fix spellcheck dictionary
* Shut down 5s after a failed login, via PAM so serial, ssh and screen all count
* Duress password via pam_duress
* Update login password to digits, Thor only
* phoc segfaults on touch-up in wlr_surface_get_root_surface, takes every app with it
* Confirm callaudiod stopped segfaulting now that the sink list is real
* Fix rotation on lockscreen (May be upstream)
* Setup Front and Rear Camera
* Validate NixTool Local install procedure and write procedure for using it to update towboot in emmc mode
* Fix Ragnarok AArch64 remote building
* Setup Build caching for zfs kernel on thor
* Fix all partlabel collisions between odin and thor
* Research phosh plugins
* Add wipefs prior to installation for disks
* * Optimize
  * Foreground booster
* Let the initrd join more than one WiFi network, it cannot unlock away from home
* WireGuard in initrd, but only after roaming, and not via the shared module
* Figure how to run android apps on pinephone
* Review and install apps

  * Login and sync firefox
  * Setup Trilium
  * Syncthing
  * Setup Matrix
  * Setup Discord
  * Setup Phone
  * Setup SMS

## Troubleshooting

Kept so the same ground is not re-covered.

| Symptom                         | Cause                                        | Solution                               |
| ------------------------------- | -------------------------------------------- | -------------------------------------- |
| Serial garbage at every baud    | Two readers on one port, not a baud mismatch | Use multiplexing with multiple readers |
| `nixos-anywhere` kexec failed | postmarketOS kernel has no`kexec_load`     | Use NixTool's local install mode       |
