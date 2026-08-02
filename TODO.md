# TODO

Outstanding work, most blocking first. Background for the Thor items is in
[docs/thor.md](docs/thor.md).

## Blocking — Thor has no network

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
