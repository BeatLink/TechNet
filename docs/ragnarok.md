# Ragnarok — backup server

|          |                                                                                       |
| -------- | ------------------------------------------------------------------------------------- |
| Device   | Pine64 Rock64 SBC, Rockchip RK3328                                                    |
| Platform | `aarch64-linux`                                                                     |
| Modules  | [`nix/0-common`](../nix/0-common) + [`nix/1-backup-server`](../nix/1-backup-server) |
| Address  | `ragnarok.technet` over WireGuard                                                   |

Ragnarok is a low-power SBC whose job is to hold backups. It is a WireGuard
client, dialling in to Heimdall.

It lives off site, at family's home, so that the backups survive physical damage
to or destruction of the house the rest of the network is in. That placement is
why it dials in over WireGuard rather than sitting on the LAN.

Despite both being quad Cortex-A53 aarch64, it shares no silicon with Thor:
Ragnarok is Rockchip RK3328, Thor is Allwinner A64. Nothing vendor-specific
transfers between them — different U-Boot targets, different DTBs, and recovery
is Rockchip maskrom rather than Allwinner FEL. Its ethernet is `dwmac_rk` +
`stmmac`, both in the initrd so the tunnel has a link to run over.

## Hardware

2 GB RAM, and three drives — nothing is internal, both the system and the data
live on USB-attached 2.5" disks:

| Use          | Size   | Format            |
| ------------ | ------ | ----------------- |
| Tow-Boot     | 32 GB  | MicroSD card      |
| NixOS        | 128 GB | 2.5" SATA USB SSD |
| Backup drive | 5 TB   | 2.5" SATA USB HDD |

Two things to know before touching it physically:

- It will not drive certain monitors over HDMI directly. An Xtech HDMI-to-VGA
  adapter in between works.
- Serial is the reliable console. Wire black to GND, white to RXD, brown to TXD,
  then:

  ```sh
  nix-shell -p minicom --run 'sudo minicom -D /dev/ttyUSB0 -b 115200 --color=on'
  ```

References — [product page](https://pine64.com/product/rock64-2gb-single-board-computer/),
[ROCK64 wiki](https://wiki.pine64.org/wiki/ROCK64),
[software releases](https://wiki.pine64.org/wiki/ROCK64_Software_Releases).

## Tow-Boot

Ragnarok boots U-Boot built through Tow-Boot. This board has no SPI flash, so
the Tow-Boot *shared disk image* goes on the 32 GB SD card instead. That is what
lets the board boot any UEFI aarch64 ISO or drive, with no board-specific imaging
or partition layout required on the target media.

It builds from a fork, on the `consolidation` branch — ROCK64/RK3328 support
on the fork's own Tow-Boot U-Boot tree (2026.04), with the Tow-Boot menu on
HDMI and USB keyboard input —
[BeatLink/Tow-Boot](https://github.com/BeatLink/Tow-Boot/tree/consolidation):

```sh
git clone https://github.com/BeatLink/Tow-Boot -b consolidation
nix-build --arg src ./Tow-Boot -A pine64-rock64
dd if=shared.disk-image.img of=/dev/XXX bs=1M oflag=direct,sync status=progress
```

## Installing NixOS

1. Download the NixOS Minimal aarch64 ISO and write it to a USB drive.
2. Format a fast SSD drive with a Linux swap partition using GParted.
3. Disconnect all other drives from the SBC, add the installation drive, and boot.
4. Connect the root drive and the swap drive after the boot screen loads.
5. Set a root password: `sudo -i`, then `passwd`.
6. Run `ifconfig` to get the IP address.
7. Enable temporary swap:

   ```sh
   swapon /dev/<path-to-swap-partition>
   mount -o remount,size=10G,noatime /nix/.rw-store
   ```

8. Run `./scripts/install.sh` from the TechNet folder.

## Backups

Borg is configured in [`borg.nix`](../nix/1-backup-server/1-system/borg.nix),
with the repository living on the data drive from
[`data-drive.nix`](../nix/1-backup-server/1-system/data-drive.nix). Other
hosts push to it; the `borg` group on each client grants repo access.

## Unlocking

Same arrangement as Heimdall — clevis against Odin's tang, enabled in
[`clevis.nix`](../nix/1-backup-server/1-system/clevis.nix), passphrase in
`secrets/1-backup-server/clevis.yaml`.

As a WireGuard *client*, its initrd recovery loop probes the server through the
tunnel (`10.100.100.1` out of `wg0`) rather than probing the LAN, since for a
client it is the tunnel itself that has to work.

## As a build host

Ragnarok is the only native `aarch64-linux` machine in the network. Odin can
build aarch64 closures through binfmt, but that is qemu emulation and slow.
Adding Ragnarok to `nix.buildMachines` on Odin would make Thor's builds native.

Two caveats: it is a modest SBC, so it is faster than emulation but not fast in
absolute terms, and it must be awake and unlocked to be useful — which, per the
tang arrangement, means Odin must be unlocked too.

## Rebuilding

```sh
nixtool run maintenance/rebuild --host Ragnarok --action dry-activate
nixtool run maintenance/rebuild --host Ragnarok --action switch
```

Builds for Ragnarok run on Odin under emulation unless a native builder is
configured, so expect them to take noticeably longer than Heimdall's.
