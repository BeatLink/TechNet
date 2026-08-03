# TODO

Outstanding work, most blocking first. Background for the Thor items is in
[docs/thor.md](docs/thor.md).

## Blocking — WiFi: second fault, behind the first

The 6.12 pin **worked** and fixed what it was meant to. On 6.18 the pwrseq probe
failed outright and the WiFi MMC host never registered at all; on 6.12:

    [3.148686] sunxi-mmc 1c10000.mmc: allocated mmc-pwrseq
    [3.174459] sunxi-mmc 1c10000.mmc: initialized, max. request size: 16384 KB
    [3.211196] mmc2: Failed to initialize a non-removable card

So the host now probes and registers as `mmc2`, and the DT does describe the
`wifi@1` child — but the RTL8723CS never answers. Note the timing: **37 ms**
from controller init to giving up, with no regulator errors.

The likely cause is that the PinePhone's `wifi-pwrseq` node carries only
`compatible` and `reset-gpios` — no `post-power-on-delay-ms`. Other boards using
this chip specify `200`. Confirmed the node is equally bare in the kernel's own
DTB at both 6.12 and 6.18, so this is not Tow-Boot supplying a stale tree.

- [ ] Add a device tree overlay setting `post-power-on-delay-ms = <200>` on
      `wifi-pwrseq`, and possibly `clocks = <&rtc CLK_OSC32K_FANOUT>` /
      `clock-names = "ext_clock"`, which mainline also omits here.
- [ ] `hardware.deviceTree.enable` is already true but `name` is null, so
      Tow-Boot's tree is used unmodified. Setting
      `hardware.deviceTree.name = "allwinner/sun50i-a64-pinephone-1.2.dtb"` plus
      `overlays` is the mechanism — but check whether Tow-Boot's UEFI honours the
      `devicetree` line systemd-boot would emit, or overrides it with its own.
- [ ] If the overlay route does not stick, the fallback is a kernel with the
      PinePhone DT patches (mobile-nixos or megi's tree) rather than mainline.

Deploying any of this still goes through Tow-Boot USB mass storage until WiFi
works — see below.

## Superseded — Thor has no network

Thor is installed and boots, but WiFi does not come up on 6.13+ (see
[13-kernel.nix](nix/5-phone/1-system/13-kernel.nix) for the full analysis). It is
pinned to 6.12 in the config, but that config is not deployed yet, and Thor
cannot be reached over the network to deploy it — the two block each other.

- [ ] Connect the phone to Odin with a USB-C **data** cable.
- [ ] Bring up the USB gadget by hand over the serial console, since the initrd
      one does not exist in the booted system:

      sudo modprobe libcomposite usb_f_ecm
      G=/sys/kernel/config/usb_gadget/g1
      sudo mkdir -p $G/strings/0x409 $G/configs/c.1/strings/0x409 $G/functions/ecm.usb0
      # ids, MACs (host 02:00:00:00:0d:02), link function into config, bind UDC
      sudo ip addr add 172.16.42.1/24 dev usb0 && sudo ip link set usb0 up

- [ ] Deploy over that link. The aarch64 closure builds natively on Ragnarok:

      nixos-rebuild switch --flake .#Thor --target-host beatlink@172.16.42.1 --sudo

- [ ] Confirm WiFi works on 6.12: `ip -br link` should show a `wlan` interface,
      and `dmesg | grep rtw` should no longer be empty.

Once that lands, the initrd gadget and WiFi both work, and future deploys need no
serial console.

## Verify on Thor after the first rebuild

None of the driver work is deployed yet; it arrives with the rebuild above.

- [ ] **Accelerometer.** The screen sits permanently on its side. The hwdb rule
      matched only `invensense,mpu6050` while the config loads `st_lsm6dsx`, so
      it likely never applied. [7-sensors.nix](nix/5-phone/1-system/7-sensors.nix)
      now covers both families. Check which part is fitted and whether a rule
      matched:

      udevadm info -a /sys/bus/iio/devices/iio:device0 | grep -i modalias
      udevadm info --export-db | grep -i ACCEL_MOUNT_MATRIX

      If a matrix now applies but the rotation is still wrong, the matrix itself
      is wrong rather than missing — the four quarter turns are in the file header.
- [ ] **Keyboard accessory.** `lsmod | grep -E 'pinephone_keyboard|ip5xxx'`, and
      whether the case's battery shows up alongside the phone's.
- [ ] **Initrd USB gadget.** It failed on first boot because the modules were
      only `availableKernelModules`; now force-loaded. Should reach
      `172.16.42.1` from initrd.
- [ ] **Battery and charging.** `upower -d` should report charge and time
      remaining.
- [ ] **No on-screen keyboard at the login screen.** The phone cannot be logged
      into without a hardware keyboard or the serial console. Phosh ships
      `squeekboard`, but the greeter needs it enabled separately from the
      session — check whether phoc/phosh's greeter is configured for it, and
      whether autologin is masking the problem rather than solving it.
- [ ] Drop the workaround: the SSH host keys were fixed by hand on Thor
      (appending the newline nixtool omitted). Confirm a fresh install no longer
      needs it.

## Clevis

Thor prompts for its passphrase on every boot; clevis is deliberately off.

- [ ] `sops secrets/5-phone/clevis.yaml` — `zfs_passphrase`, **identical** to
      `thor_encryption_key` in `secrets/3-laptop/nixtool.yaml`.
- [ ] `sudo rebind-clevis` on Thor, with tang reachable.
- [ ] Set `enable = true` in [9-clevis.nix](nix/5-phone/1-system/9-clevis.nix)
      and `nixos-rebuild boot`.

It only unlocks where tang is reachable **and** Odin's session is unlocked, so
away from home it still prompts. Keep the passphrase — ZFS native encryption has
one wrapping key per encryption root and no spare keyslots.

## USB gadget does not work on a mainline kernel

Settled by a controlled test: keyboard case removed, cable connected, phone
booted into Linux, gadget correctly created by the initrd module.

    axp20x-usb: online=1 type=USB     <- VBUS present, phone charging
    udc state:  not attached          <- no host on the data lines

Power flows and the PMIC sees it; the musb controller never sees a host. So the
cable, the port and the case are all fine — the ANX7688 muxes the USB-C data
path and sets the role, and its driver has never been merged. `/sys/class/usb_role/`
and `/sys/class/typec/` are both empty, so there is nothing to switch.

postmarketOS works because megi's tree carries that driver; Tow-Boot works
because U-Boot programs the ANX7688 itself. Charging works on mainline precisely
because it needs no data path.

This is not fixable by configuration. It needs an out-of-tree kernel.

This undercuts two things built on the assumption that it would work:

- [ ] [10-initrd-usb-gadget.nix](nix/5-phone/1-system/10-initrd-usb-gadget.nix) —
      cannot attach, so clevis can never reach tang over USB. Either drop it, or
      keep it dormant against a future kernel that carries the driver.
- [ ] [19-thor-usb-link.nix](nix/3-laptop/1-system/19-thor-usb-link.nix) on Odin —
      the matching half, equally inert.
- [ ] Decide how Thor is meant to unlock at all. WiFi in initrd needs
      wpa_supplicant plus the PSK in an initrd on an unencrypted ESP, which was
      rejected earlier for good reason. The remaining options are entering the
      passphrase by hand, or an out-of-tree kernel.

Deploying to an offline Thor therefore goes through Tow-Boot USB mass storage:
expose the eMMC, unlock the pool on Odin, `nix copy` the closure in, and run
`switch-to-configuration boot` under `nixos-enter`. No wipe involved.

Two things that make Tow-Boot's UMS work, both learned the hard way:

- **Take the phone out of the keyboard case.** The case supplies 5V over the
  pogo pins, which stops the USB-C port entering peripheral mode. Tow-Boot
  cheerfully reports `Allwinner mUSB OTG (Peripheral)` while the host sees
  nothing at all.
- **Connect the cable before starting UMS.** Tow-Boot binds the gadget when the
  command starts; attaching a host afterwards does not make it re-enumerate.
  Ctrl+C does not return to the menu either -- it falls through and boots.

Never use `-a` forms while the phone's disk is attached. `zpool export -a`,
`zfs unmount -a` and friends act on Odin's own pools too, and the partlabels
collide so `/dev/disk/by-partlabel/disk-root-drive-efi` resolves to whichever
disk udev saw last. Name the pool and mount by device node.

## Known bugs

- [ ] **Partlabel collision between Odin and Thor.** Odin's fstab resolves
      `/boot` via `/dev/disk/by-partlabel/disk-root-drive-efi`, and Thor's disko
      config produces the *same* partlabel. While the phone's disk is attached
      over USB that symlink is ambiguous, and Odin's `/boot` silently unmounted
      during the install — its next bootloader install failed as a result.
      Nothing was damaged, but a bootloader write during that window could have
      gone to the phone's ESP.

      Fix either by giving each host a distinct partlabel, or by having
      `install-local` assert `/boot` is still the local ESP after disko runs.
- [ ] **`nixos-anywhere` cannot install a PinePhone.** Recorded in
      [docs/thor.md](docs/thor.md#installing); `install-local` exists because of
      it. No action unless upstream gains kexec on postmarketOS.
- [ ] **`RESET_GPIO` upstream fix.** The 3-cell patch is still an unmerged RFC.
      Recheck on kernel bumps; when it lands, drop the 6.12 pin.

## Deferred

- [ ] **Build the patched 6.18 kernel** (`RESET_GPIO=n`, commented out in
      [13-kernel.nix](nix/5-phone/1-system/13-kernel.nix)) on Ragnarok and move
      Thor back off the 6.12 pin. Not cached, so it is a full kernel build —
      hours even natively.
- [ ] **`nix flake update nixtool`.** The lock is pinned to `7e0ff63a`, which
      predates the SSH-key newline fix and the build-before-partition reordering.
      Both are pushed but not locked here.
- [ ] **Commit the working tree** — remote-builder modules for Odin and Ragnarok,
      and Thor's kernel pin.
- [ ] **`boot.initrd.network.enable`** on Thor. initrd SSH is already enabled but
      unusable without it, so a stuck boot currently needs the serial console.
- [ ] **Camera.** `sun6i-csi` and the sensor drivers exist but mainline PinePhone
      camera support is poor and needs app-side work. A project, not a setting.

## Reference — resolved this session

Kept so the same ground is not re-covered.

| Symptom | Cause |
| --- | --- |
| Serial garbage at every baud | Two readers on one port, not a baud mismatch |
| `nixos-anywhere` kexec failed | postmarketOS kernel has no `kexec_load` |
| Every aarch64 builder exited 255 | binfmt registered `P` not `PF`; interpreter invisible inside the chroot |
| `zpool` aborted under qemu | disko script built for aarch64; ZFS ioctls cross an ABI |
| disko found a pool that "already exists" | `wipefs` on the disk leaves ZFS labels inside partitions |
| sshd: `invalid format` | OpenSSH needs a trailing newline after the PEM footer |
| Install died mid-copy | USB disk dropped; ZFS suspended the pool and only a reboot cleared it |
