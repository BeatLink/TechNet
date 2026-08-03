# TODO

Outstanding work, most blocking first. Background for the Thor items is in [docs/thor.md](docs/thor.md).



## Thor

* `nix flake update nixtool`
* Fix Data Root ZFS
* Set display scale to 175% by default
* Fix spellcheck dictionary
* Setup FLOW apn
* Fix rotation on lockscreen (May be upstream)
* Plymouth and graphical decryption
* Setup Front and Rear Camera
* Validate NixTool Local install procedure and write procedure for using it to update towboot in emmc mode
* Fix Ragnarok AArch64 remote building
* Setup Build caching for zfs kernel on thor
* Fix all partlabel collisions between odin and thor
* Review and install apps.

  * Mobile Friendly KeepassXC database
  * Login and sync firefox
  * Setup Trilium
  * Setup Matrix
  * Setup Discord
  * Setup Phone
  * Setup SMS




## Troubleshooting

Kept so the same ground is not re-covered.

| Symptom                                  | Cause                                                                                                                    | Solution |
| ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | -------- |
| Serial garbage at every baud             | Two readers on one port, not a baud mismatch                                                                             | Use     |
| `nixos-anywhere` kexec failed          | postmarketOS kernel has no`kexec_load`                                                                                 |          |
| Every aarch64 builder exited 255         | binfmt registered`P` not `PF`; interpreter invisible inside the chroot                                               |          |
| `zpool` aborted under qemu             | disko script built for aarch64; ZFS ioctls cross an ABI                                                                  |          |
| disko found a pool that "already exists" | `wipefs` on the disk leaves ZFS labels inside partitions                                                               |          |
| sshd:`invalid format`                  | OpenSSH needs a trailing newline after the PEM footer                                                                    |          |
| Install died mid-copy                    | USB disk dropped; ZFS suspended the pool, only a reboot cleared it                                                       |          |
| Clients never synced time                | FTL advertises itself as NTP via DHCP but udp/123 was closed, and timesyncd never falls back once a server is configured |          |
| Tow-Boot UMS invisible to host           | Keyboard case attached; its 5V on the pogo pins blocks peripheral mode                                                   |          |
