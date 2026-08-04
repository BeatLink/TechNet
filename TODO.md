# TODO

Outstanding work, most blocking first. Background for the Thor items is in [docs/thor.md](docs/thor.md).

## Thor

* Optimize
* ethernet and docking
* Fix fwupdate
* [www.freedesktop.org/wiki/Specifications/desktop-bookmark-spec/?__goaway_challenge=meta-refresh&amp;__goaway_id=df93c11d9ee5b312d692e413745c8585&amp;__goaway_referer=https%3A%2F%2Fduckduckgo.com%2F](https://www.freedesktop.org/wiki/Specifications/desktop-bookmark-spec/?__goaway_challenge=meta-refresh&__goaway_id=df93c11d9ee5b312d692e413745c8585&__goaway_referer=https%3A%2F%2Fduckduckgo.com%2F)
* Setup Waydroid
* Fix spellcheck dictionary
* Update login password to number only
* Fix call app crashing
* Fix call audio
* Fix rotation on lockscreen (May be upstream)
* Plymouth and graphical decryption
* Setup Front and Rear Camera
* Validate NixTool Local install procedure and write procedure for using it to update towboot in emmc mode
* Fix Ragnarok AArch64 remote building
* Setup Build caching for zfs kernel on thor
* Fix all partlabel collisions between odin and thor
* Research phosh plugins
* Add wipefs prior to installation for disks
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
