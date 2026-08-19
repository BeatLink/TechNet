# Tow-Boot — firmware for Thor and Ragnarok

Both aarch64 boards in the network boot through Tow-Boot, built from a personal
fork rather than upstream releases. This is the state of that fork: what it
builds, where it lives, and how firmware reaches a board.

Per-host context is in [Thor](thor.md) and [Ragnarok](ragnarok.md); this page is
the firmware itself, common to both.

## Repositories and branches

| Repository | Branch | Role |
| ---------- | ------ | ---- |
| [BeatLink/Tow-Boot](https://github.com/BeatLink/Tow-Boot) | `rock64-pinephone-fixes` | trunk — all board and module work |
| [BeatLink/Tow-Boot](https://github.com/BeatLink/Tow-Boot) | `development` | upstream tip, unmodified |
| [BeatLink/U-Boot](https://github.com/BeatLink/U-Boot) | `tb-2026.04-dev` | the U-Boot tree everything builds from |

`BeatLink/Tow-Boot` forks `Tow-Boot/Tow-Boot`; `BeatLink/U-Boot` forks
`Tow-Boot/U-Boot`. The working checkout is
`/Storage/Files/Projects/Coding/Pinephone/Tow-Boot`, with the U-Boot tree beside
it in `tow-boot-uboot`.

## The U-Boot tree

`tb-2026.04-dev` is Tow-Boot's own U-Boot tree — historically a 2023.07 base —
ported forward to **2026.04**, carrying:

- Tow-Boot's UX: the `tb_menu` curses menu on PDCursesMod, splash and autoboot
  handling, Tow-Boot branding, the opinionated boot flow, predictable boot
  order, the vibrator uclass and the LRADC button driver.
- The PinePhone display and button work written here: a sun6i MIPI-DSI host,
  TCON0 in DSI mode, the Xingbangda XBD599 panel, the AXP803 GPIO LDOs,
  backlight interpolation, the LRADC and AXP power keys as a keyboard, and
  volume-up at power-on entering USB mass storage.

Rockchip's predictable boot order is implemented against bootstd `BOOT_TARGETS`
rather than the removed distro-boot macros. Anything upstream fixed on its own
between 2023.07 and 2026.04 was dropped rather than ported.

`modules/tow-boot/src.nix` pins the tree by revision and hash. **Changing the
tree means pushing it and bumping both**, or the build silently keeps using the
old revision.

## Boards

Both set `buildUBoot = false`, so both get the full Tow-Boot experience.

**`pine64-pinephoneA64`** (Thor) — keeps `phone-ux` (LED and vibrator feedback)
and adds the panel: U-Boot's console and the boot menu render on the screen, the
volume and power keys drive the menu, and the framebuffer reaches EFI as a GOP
so systemd-boot is readable on the phone. `PDCURSES_PREFER_VIDCONSOLE` makes the
menu size itself to the panel rather than to whatever the serial terminal
reports. Holding volume up at power-on still enters USB mass storage, which is
what Thor's install procedure depends on.

**`pine64-rock64`** (Ragnarok) — RK3328 support: board file, RK3328 ATF, the SPI
SD-layout install path, HDMI output with USB keyboard input and a
serial/vidconsole mux, and an LPDDR3-666 memory timing fix. The bootstd
`bootflow scan` overrides apply only to stock builds, so this build keeps the
Tow-Boot boot flow.

## Building

From the Tow-Boot checkout:

```sh
nix-build -A pine64-pinephoneA64      # or -A pine64-rock64
```

Thor's firmware takes personal overrides on top — currently a 5-second boot
delay, which `phone-ux` otherwise forces to zero for the blind UX. Build that
one from this repo, through
[`nix/5-phone/firmware.nix`](../nix/5-phone/firmware.nix):

```sh
nix-build nix/5-phone/firmware.nix -A pine64-pinephoneA64
```

NixTool's `formatting/flash-towboot` builds from the same checkout, via its
`TOWBOOT_REPO` and `TOWBOOT_DEVICE` variables.

## Deploying to Thor

The A64 boot ROM prefers the SD card, so the card wins over the eMMC boot
partition — which makes the SD the safe place to test, and pulling the card the
way back out.

```sh
scp result/binaries/Tow-Boot.noenv.bin beatlink@thor.technet:/tmp/
ssh beatlink@thor.technet 'sudo dd if=/tmp/Tow-Boot.noenv.bin \
    of=/dev/mmcblk0p1 bs=1024 conv=fsync'
```

**Write to `/dev/mmcblk0p1`, never to the whole disk or the shared disk
image** — partition 2 of that card holds `data-pool-Thor`. Writing the partition
is bounded by the kernel and cannot reach the pool.

Thor's eMMC `boot0` still carries an older, pre-fork build as a fallback.
Installing the current firmware there — the procedure is in [Thor](thor.md) —
means giving that up, so it is worth leaving until this build has been lived
with.

Ragnarok has no SPI flash, so its firmware is the shared disk image written to
its own SD card; see [Ragnarok](ragnarok.md).

## Provenance

The tree is three commits over U-Boot v2026.04, grouped by what they do:
video, the buttons, and the Tow-Boot patch set itself. Most of that patch set
is other people's work, cherry-picked from `Tow-Boot/U-Boot` — chiefly Samuel
Dionne-Riel's. Squashing collapsed the individual cherry-picks, so each commit
message lists the original commit IDs it came from and carries
`Co-authored-by` trailers for everyone in it. That is the only remaining record
of who wrote what; keep it intact when rewriting further.

The PinePhone display and button drivers were written here and were once kept
as a patch series aimed at the U-Boot mailing list. That is no longer the plan,
and the series has been folded into the domain commits along with everything
else.
