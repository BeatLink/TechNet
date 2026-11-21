# Rock64 — spare board

|          |                                                                              |
| -------- | ---------------------------------------------------------------------------- |
| Device   | Pine64 Rock64 SBC, Rockchip RK3328                                           |
| Platform | `aarch64-linux`                                                              |
| Modules  | [`nix/0-common`](../nix/0-common) + [`nix/6-rock64`](../nix/6-rock64)        |

The Rock64 was [Ragnarok](ragnarok.md), the backup server, until that role
moved to an Acer laptop on 2026-11-21 and took both drives with it. Its
configuration is kept as a basic system with no services: no backups, no
Syncthing, no WireGuard peer, no monitoring agents and no X-Nix deployment.

Before it can be installed it needs two things this repository does not have
yet. The root drive in
[`root-drive-disko.nix`](../nix/6-rock64/1-system/root-drive-disko.nix) is a
placeholder path, because the board has no drive of its own. And the board
needs a host key of its own listed in `.sops.yaml`, because the shared secrets
every host reads, the user's password among them, are encrypted to each host's
key and Ragnarok's key stayed with Ragnarok.

Despite both being quad Cortex-A53 aarch64, it shares no silicon with Thor:
this board is Rockchip RK3328, Thor is Allwinner A64. Nothing vendor-specific
transfers between them — different U-Boot targets, different DTBs, and recovery
is Rockchip maskrom rather than Allwinner FEL. Its ethernet is `dwmac_rk` +
`stmmac`, both in the initrd, and its MAC was `b6:9e:63:ff:6b:90`.

## Hardware

2 GB RAM and a 32 GB MicroSD card carrying Tow-Boot. Nothing is internal: as
Ragnarok, both the system and the data lived on USB-attached 2.5" disks. What
follows describes that arrangement, which
[`hardware-configuration.nix`](../nix/6-rock64/1-system/hardware-configuration.nix)
still carries the settings for.

### USB layout

Both drives share the board's one USB 3 port through a hub, and the hub and
the board each run from their own 5V 3A supply:

| Part         | Device                                                  | Protocol    |
| ------------ | ------------------------------------------------------- | ----------- |
| Hub          | Xtech XTC-391, Genesys `05e3:0626` / `05e3:0610`        |             |
| Root SSD     | Sabrent enclosure, JMicron `152d:0583`, hub port 2      | UAS         |
| Backup drive | Sabrent adapter, JMicron JMS576 `152d:0576`, hub port 1 | usb-storage |
| Spare        | Sabrent enclosure, JMicron JMS561U `152d:1561`          | usb-storage |

Three things about it are deliberate, and each was a fault before it was
fixed:

- **The 5V wire of the hub's upstream cable is cut.** The hub ties its supply
  straight to that wire, so it fed the board backwards through the USB 3
  port: the board stayed up on the hub's supply alone with its own unplugged.
  With the wire cut the hub and drives run only from the hub's supply, and
  the drives do not power up until it is plugged in.
- **The hub needs its supply, and a 3A one.** The 5 TB drive draws about 1.2A
  while it spins up, more than the 0.9A a USB 3 port provides, and the two
  drives, their adapters and the hub together peak a little over 2A. On a 2A
  supply the backup drive's adapter took a transfer-error reset every two to
  three minutes under concurrent reads from both drives; on 3A the same test
  saw one.
- **The root SSD is not in the JMS561U.** That enclosure aborted commands
  under UAS, dropped off the bus after enumeration, and was slow to appear
  behind the hub even on Odin.

What remains is the occasional reset on the backup drive's adapter: five
`Transfer error` lines on its bulk-in endpoint, then `reset SuperSpeed USB
device`. The read is retried, and most of the time no I/O error is logged. The
drive's SMART power counters (192 Power-Off_Retract_Count, 12
Power_Cycle_Count) do not move across one, so it is not the drive losing
power. The RK3328's USB 3 controller has no PHY driver in mainline Linux and
is known to fail with two SuperSpeed disks behind a hub.

Holding the adapter to 64 sectors, 32 KiB a request, did not stop them: over
the 47 hours from 2026-11-11 02:17 the backup drive's adapter was reset 26
times, 25 of them on 2026-11-11 and one on 2026-11-12, at worst five in an
hour, and the rule is back at 1024 sectors. The kernel logged 21 I/O
errors on that drive in that time, and btrfs logged 260 reads corrected from
its second copy.

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

The board boots U-Boot built through Tow-Boot. This board has no SPI flash, so
the Tow-Boot *shared disk image* goes on the 32 GB SD card instead. That is what
lets the board boot any UEFI aarch64 ISO or drive, with no board-specific imaging
or partition layout required on the target media.

It builds from a fork, on the `rock64-pinephone-fixes` branch — ROCK64/RK3328
support on the fork's own Tow-Boot U-Boot tree (2026.04), with the Tow-Boot menu
on HDMI and USB keyboard input. [Tow-Boot](tow-boot.md) describes the fork.
This board's build sets its own preboot and drops network boot, through
[`nix/6-rock64/firmware.nix`](../nix/6-rock64/firmware.nix):

```sh
nix-build nix/6-rock64/firmware.nix -A pine64-rock64
```

A fresh card takes the whole image, from NixTool's `formatting/flash-towboot`
or by hand:

```sh
dd if=result/shared.disk-image.img of=/dev/XXX bs=1M oflag=direct,sync status=progress
```

A card that already carries Tow-Boot only needs its firmware partition
rewritten. That works on the running board — the card is not mounted once
Linux is up — and the write is bounded by the kernel to the partition. The
firmware fills partition 1, sectors 64 to 24639:

```sh
dd if=result/shared.disk-image.img of=part1.bin bs=512 skip=64 count=24576
scp part1.bin rock64:/tmp/
ssh rock64 'sudo dd if=/tmp/part1.bin of=/dev/mmcblk1p1 bs=1M oflag=direct conv=fsync'
```

The card is `mmcblk0` or `mmcblk1` depending on the boot; `lsblk -o NAME,PARTLABEL`
shows which one carries the `Firmware (Tow-Boot)` partition.

It takes effect at the next reboot.

### Firmware console

The Tow-Boot prompt and menu are on HDMI and serial only, and USB is started
before the prompt so a keyboard works from power-on. The firmware has no
netconsole: U-Boot's sends the console as plain UDP and takes input from
anyone on the LAN, so a host there could drive the boot menu and boot a kernel
of its own, and there is no way to encrypt it.

### What preboot does

Preboot only scans USB, so a keyboard is a console device before the boot
prompt and the root disk is there to boot from.

The boot order itself is not set here. `TOW_BOOT_NETWORK_BOOT = no` drops PXE
and DHCP from the order the firmware is built with, leaving eMMC, SD and USB,
because a board that boots its own disks otherwise spends about a minute
timing out on TFTP before the menu appears. Both commands are still there to
be run by hand.

### When the root disk is not found, or stops answering

The RK3328's USB 3 PHY has a known erratum: it never tells the controller
that a device has disconnected, and mainline Linux has no driver for the
polling workaround Rockchip's vendor kernel uses. The JMS561U enclosure the
root SSD used to sit in tripped it in two ways, both of which the firmware
console shows:

- After a warm reboot it is often invisible to the firmware: `usb start`
  finds it on no bus, or it has fallen back to USB 2, where U-Boot's EHCI
  fails to re-reset after a few `usb reset` cycles and once crashed the
  firmware outright with a Synchronous Abort during that teardown.
- On a cold boot it sometimes drops off the bus right after enumeration: the
  firmware prints its capacity, then the first partition read fails and every
  transfer after it halts an endpoint. Linux sees the same drop on its own
  first enumeration every boot and re-enumerates; that is what the
  `usbcore.quirks` entry in
  [`hardware-configuration.nix`](../nix/6-rock64/1-system/hardware-configuration.nix)
  is for.

Neither is a stall the firmware can clear; only a fresh enumeration brings the
bridge back. The boot flow asks for one itself: the fork's `usb_boot` scans
twice and runs `usb_rescan`, a plain `usb reset`, between the passes. The
fork's storage layer also gives up on a device after eight failed transports
in a row, so the first pass ends in seconds rather than the twelve minutes of
bounded retries it used to cost; see [Tow-Boot](tow-boot.md).

The firmware cannot cut the drives' power. GPIO `A2` gates the 5V rail for
every USB port on this board, but the drives sit behind a hub that runs from
its own supply, with the 5V wire of its upstream cable cut so it cannot feed
the board. A bridge that a `usb reset` does not bring back needs the hub's
supply unplugged and plugged back in.

`usb reset`, followed by `usb storage` and `run bootcmd`, recovers a board by
hand from the firmware console on serial, or on HDMI with a USB keyboard,
once the Tow-Boot menu's *Firmware Console* entry is chosen.

## Freeze recovery

[`freeze-recovery.nix`](../nix/6-rock64/1-system/freeze-recovery.nix)
reboots a frozen board through softdog, the kernel's software watchdog, which
systemd feeds every 30s. The RK3328's own DesignWare watchdog is disabled in
the device tree, because its reset leaves the board dead until a power cycle.
With that node disabled softdog is `/dev/watchdog0`.

Pointing the watchdog at the reset a normal reboot uses does not help. The
firmware was built to set bit 14 of `CRU_GLB_CNT_TH`, which selects the first
global reset over the default second one, and with the bit read back as set
(`md.l 0xff440090` gave `3a984064`) starting the watchdog from the U-Boot
prompt with `mw.l 0xff1a0000 1` still hung the board on 2026-11-11. The
firmware change was reverted.

Softdog runs on a kernel timer, so a lockup hard enough to stop timers is not
recovered. The `hung_task`, `softlockup` and `hardlockup` panic sysctls and
`panic=10` cover what they can of that gap.

One such lockup is known. Reading a block whose two btrfs copies are both
bad logs a warning and an error per block, and with every console at info
level and the journal forwarded to serial, a run of those froze the board
three times on 2026-11-10 and 11, softdog included. The kernel has one
console level for all consoles and the serial one runs at 115200 baud, so
the level stays at the command line's 3: serial and HDMI carry panics and
oopses only, and the journal is not forwarded to serial.

Nothing is sent over the network, since log lines can carry sensitive detail.
Everything goes to the persistent journal on the board, which syncs to disk
every five seconds so a hard lockup loses little, and `memory-trail` logs
memory use to it every five seconds.
