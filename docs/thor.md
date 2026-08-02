# Thor — PinePhone

| | |
| --- | --- |
| Device | Pine64 PinePhone (1.2), Allwinner A64 |
| Platform | `aarch64-linux` |
| Modules | [`nix/0-common`](../nix/0-common) + [`nix/5-phone`](../nix/5-phone) |
| Root disk | eMMC, `mmc-ASTCXX_0xd1002721` |
| Address | `thor.technet`, `10.100.100.4` over WireGuard |

Thor runs the common configuration plus a phone-specific layer: the modem and
SMS stack in [`3-apps/comms`](../nix/5-phone/3-apps/comms), display and sensor
setup, and NetworkManager profiles for WiFi and the WireGuard tunnel.

The mobile-nixos device import in
[`1-hardware-configuration.nix`](../nix/5-phone/1-system/1-hardware-configuration.nix)
is commented out; only its firmware package is used. Thor boots via Tow-Boot,
which provides UEFI, so the bootloader is systemd-boot rather than extlinux.

## Serial console

The PinePhone's 3.5 mm jack doubles as a UART console. **DIP switch 6** under the
back cover selects which: off = serial, on = headphones.

**115200 8N1, no flow control.** Confirmed against a live Tow-Boot boot with the
official Pine64 TRRS console cable (a CH340, `1a86:7523`, enumerating as
`/dev/ttyUSB0`).

```sh
nix-shell -p picocom --run 'picocom -b 115200 /dev/ttyUSB0'
```

`beatlink` is in `dialout`, so no `sudo` is needed.

Only one process may read the port at a time. Two readers — minicom and a second
capture, say — each receive part of the byte stream, which looks exactly like a
wrong baud rate: structured, repeating, but unreadable. If output is garbled,
check for a second reader before touching the baud rate.

The adapter re-enumerates whenever the USB bus resets, which kills whatever is
attached to it. Watching the stable `by-id` path and reattaching in a loop
survives that:

```sh
while true; do
    [ -e /dev/serial/by-id/usb-1a86_USB_Serial-if00-port0 ] &&
        picocom -b 115200 /dev/serial/by-id/usb-1a86_USB_Serial-if00-port0
    sleep 2
done
```

## Installing

Thor cannot be installed with `nixos-anywhere`, which needs a running system it
can SSH into and `kexec` from. Neither environment available on a PinePhone can
do both:

| | network | kexec | nix |
| --- | --- | --- | --- |
| postmarketOS | yes | **no** — `kexec_load` returns `ENOSYS` | no |
| generic NixOS aarch64 installer | **no** — no PinePhone platform support | yes | yes |

The generic installer has no usable interface at all: the USB gadget cannot
attach (`usb_phy_generic` fails to bind a VBUS regulator, and there is no
`anx7688` driver for the USB-C controller), and WiFi never enumerates because
`pwrseq_simple` fails with `reset control not ready`, so the chip is never
brought out of reset.

So Thor is installed from Odin over USB mass storage instead, with
`install/install-local`.

### 1. Boot Thor into Tow-Boot's USB mass storage mode

Hold **volume up** during boot to reach the Tow-Boot menu and select USB Mass
Storage. Tow-Boot drives USB from U-Boot's own stack, so none of the Linux
driver gaps above apply.

### 2. Connect Thor to Odin and identify the disk

Use a USB-C **data** cable, directly — not through a dock, which can put the
phone's port into host mode.

```sh
lsblk -o NAME,SIZE,TYPE,MODEL
```

The eMMC appears as a ~29G disk with model `UMS disk 0`. Confirm the path before
continuing: it is a local disk, so a wrong path destroys Odin's data.

### 3. Run the install

```sh
nixtool run install/install-local --host Thor --target-disk /dev/sdX
```

The passphrase and both host keys come from `secrets/3-laptop/nixtool.yaml` via
sops; nothing is typed. The command partitions with disko, seeds
`/persistent/etc/ssh` so Thor boots with the identity sops expects, runs
`nixos-install`, then unmounts and exports the pool.

`install-local` applies two `lib.mkForce` overrides through `extendModules`, both
**for the partitioning step only**. The system that gets installed is built from
the unmodified configuration, and `/boot` resolves to
`/dev/disk/by-partlabel/…`, so nothing about Odin is ever baked in and the repo
needs no temporary edit.

- **The device**, because Thor's config names the eMMC by its own `by-id` path,
  which is not where it appears while attached to Odin.
- **`nixpkgs.hostPlatform`**, because the partitioning runs on Odin. Built from
  Thor's own platform, the disko script carries *aarch64* binaries; an emulated
  `zpool` issues ioctls to Odin's x86_64 ZFS module across an ABI it does not
  match and aborts with `uncaught target signal 6`. The layout itself is
  architecture-independent, so only the tools change.

### 4. After first boot

Clevis is deliberately disabled during installation, because
`boot.initrd.clevis.devices` reads the JWE at **build** time and it does not
exist yet. Once Thor boots:

```sh
sops secrets/5-phone/clevis.yaml          # zfs_passphrase, same value as thor_encryption_key
sudo rebind-clevis                        # needs tang reachable
```

then set `enable = true` in
[`9-clevis.nix`](../nix/5-phone/1-system/9-clevis.nix) and `nixos-rebuild boot`.

### Troubleshooting

**`keylocation may only be set on encryption roots`** — a pool of the same name
already exists on the disk and is imported, so disko tried to adapt it rather
than replace it. Destroy it and wipe the disk first. Name the pool explicitly;
never `zpool destroy -a` or `export -a`, since Odin's own pools are imported:

```sh
sudo zpool destroy -f root-pool-Thor
sudo wipefs -a /dev/sdX
```

**`uncaught target signal 6 (Aborted)` from `zpool`** — the disko script was
built for Thor's architecture and is running under emulation. `install-local`
forces `nixpkgs.hostPlatform` to the host's own system to avoid this; a
hand-rolled `nix build` of `diskoScript` will hit it.

## Unlocking

Thor's root pool uses ZFS native encryption with a passphrase. Clevis unlocks it
against Odin's tang server, which means it only unlocks where tang is reachable
**and** Odin's session is unlocked — see [odin.md](odin.md). Away from home it
falls back to prompting.

Initrd networking comes from the USB gadget in
[`10-initrd-usb-gadget.nix`](../nix/5-phone/1-system/10-initrd-usb-gadget.nix),
which brings up a CDC ECM link on `172.16.42.1` and reaches tang at
`172.16.42.2`. The matching side on Odin is
[`19-thor-usb-link.nix`](../nix/3-laptop/1-system/19-thor-usb-link.nix).

The passphrase is stored as `zfs_passphrase` in `secrets/5-phone/clevis.yaml`.
Keep it — ZFS native encryption has exactly one wrapping key per encryption root
and no spare keyslots, so losing it means reinstalling.
