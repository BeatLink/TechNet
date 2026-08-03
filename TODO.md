# TODO

Outstanding work, most blocking first. Background for the Thor items is in
[docs/thor.md](docs/thor.md).

## Blocking — the battery will not take charge

Nothing else on Thor can be tested until this is settled: the radios run off the
battery rail, not off USB. Pine64 state it plainly — the modem and WiFi/Bluetooth
"do not work without a battery and with a drained battery, even when enough power
is supplied via the USB Type-C port". The device tree agrees:
`vmmc-supply = <&reg_vbat_wifi>` feeds the radio from the battery.

Readings have not moved across a wall charger, a low-wattage supply and the
keyboard dock, over more than an hour:

    status       Charging      <- claims charging
    current_now  0             <- but nothing flows, on any supply
    voltage_now  126000        (0.13V, against a 2.9V minimum)
    energy-full  0 Wh          <- gauge cannot characterise the pack at all

The driver is not at fault: `in_voltage2_raw` 116 x scale 1.1 = 127.6mV, exactly
what it reports. All three ADC voltage channels read near zero, so nothing sees a
cell. A fixed voltage with zero current is an open circuit, not a slow charge —
either the pack's protection has latched permanently or the cell is dead.

Available input current is **not** the constraint, contrary to an earlier theory
here. Under JumpDrive the PMIC reports `input_current_limit = 3000000` and
`current_max = 1500000`, so 1.5A is on offer and nothing is taking it.

- [ ] **Measure the pack across + and - with a multimeter, out of the phone.**
      This is the cheap test that settles it. ~0V means the cell is gone;
      3-something means the cell is fine and the fault is in the phone's charging
      path.
- [ ] Currently charging under JumpDrive, which is the best case the phone can
      offer: 1.5A available and near-zero draw, and it sidesteps the auto-boot
      loop that was burning the trickle. JumpDrive's kernel has no
      `axp20x_battery` — no `/lib/modules`, no `modprobe`, so it cannot be added —
      so progress is only readable by booting NixOS afterwards.
- [ ] If hours under JumpDrive change nothing, replace the pack. It is a Samsung
      J7 form factor (`EB-BJ700BBC`), widely available; Pine64 sell one directly,
      which removes any doubt about contact layout and protection circuitry.
- [ ] Do **not** improvise a charger. USB is 5V against a 4.2V maximum with no
      current limit, and a cell that has sat at 0.13V is the highest-risk case
      there is. A bench supply at ~4.0V with a 50-100mA limit is the legitimate
      version; a NiMH charger such as the BQ-CC65 is the wrong chemistry entirely.

## Decided — move Thor to an out-of-tree kernel

The ANX7688 USB-C controller has no mainline driver, and that single gap costs
three separate things:

| Wanted | Blocked by |
| --- | --- |
| USB gadget networking | no role detection, UDC reports `not attached` |
| DisplayPort alt mode | no Type-C port registers, so nothing to mux |
| USB-PD negotiation | no PD at all |

Confirmed by a controlled test — case off, cable connected, gadget correctly
created — `axp20x-usb` shows `online=1` while the UDC still reads `not attached`.
Power flows, data does not. `/sys/class/usb_role/` and `/sys/class/typec/` are
both empty. `typec_displayport` and the whole Type-C stack are already present
and inert, because alt mode discovery needs a port controller to negotiate first.

postmarketOS works because megi's tree carries the driver; Tow-Boot works because
U-Boot programs the ANX7688 itself.

- [ ] Evaluate mobile-nixos or megi's kernel for Thor. It would settle the USB
      gadget, DisplayPort, keyboard DT node and probably the WiFi items together,
      rather than patching each separately against mainline. The mobile-nixos
      device import is already in the flake, commented out in
      [1-hardware-configuration.nix](nix/5-phone/1-system/1-hardware-configuration.nix).
- [ ] Then revisit the DT patching in
      [14-devicetree.nix](nix/5-phone/1-system/14-devicetree.nix) — most of it may
      become unnecessary.

## WiFi — where it actually stands

Not resolved, and every test so far was run with an unpowered chip, so none of it
is conclusive. Retest properly once the battery holds charge.

What was established independently of the battery:

- **`RESET_GPIO` regression is real.** On 6.13+ `pwrseq_simple` fails outright, so
  the WiFi MMC host never registers. Traced through kernel source and confirmed by
  an upstream RFC: `__reset_add_reset_gpio_device()` handles only `#gpio-cells=2`
  and Allwinner uses 3. From `73bf4b7381f7` in v6.13-rc1; the fix is unmerged.
- **Mainline master deletes `wifi_pwrseq` entirely**, powering the chip from
  `reg_vbat_wifi` alone. [14-devicetree.nix](nix/5-phone/1-system/14-devicetree.nix)
  now matches that, which also sidesteps the regression — no pwrseq means nothing
  consults the broken code path.

What was tried and did not help, though all of it ran on a dead battery:

| Attempt | Result |
| --- | --- |
| 6.12 (predates the regression) | host registers, card never answers |
| 6.12 + `post-power-on-delay-ms = <200>` | failure moved 37ms -> 250ms, still fails |
| 6.12, pwrseq removed | still fails |
| 6.18, pwrseq removed (current) | untested — deployed but battery died first |

- [ ] Retest on a charged battery **before** changing anything further.
- [ ] If it works, check whether the DT patch is needed at all, or whether stock
      would now do.

## Keyboard accessory needs a device tree node

The dock is connected and talking, but neither the keyboard nor its battery
appears, because mainline's DTB does not describe the accessory. Instantiating it
by hand gets most of the way:

    echo pinephone-keyboard 0x15 > /sys/bus/i2c/devices/i2c-2/new_device

    input: PinePhone Keyboard as .../i2c-2/2-0015/input/input5
    pinephone-keyboard 2-0015: Failed to request IRQ: -22

So the hardware answers at 0x15 on `1c2b400.i2c` (i2c-2, `&i2c1`) and the driver
creates an input device, then dies on `request_irq`. `new_device` supplies a bus
and an address; an interrupt can only come from a DT node.

The dock's battery follows from this: the IP5209 sits behind the keyboard
controller's I2C passthrough, so `ip5xxx_power` cannot bind until the keyboard
driver probes cleanly. Adding the modules in
[12-keyboard.nix](nix/5-phone/1-system/12-keyboard.nix) was necessary but not
sufficient.

- [ ] Add a DT node for the keyboard on `&i2c1` at 0x15 with `interrupt-parent`
      and `interrupts`. Take the GPIO from postmarketOS's overlay rather than
      guessing. Likely moot if the out-of-tree kernel lands first.

## The accelerometer is an MPU6050

`iio:device1: mpu6050`. The original hwdb rule targeting `invensense,mpu6050` was
right all along, and the theory that it never matched — because
`boot.kernelModules` loads `st_lsm6dsx` — was wrong. If the screen is still
sideways, the fault is the **matrix value**, not the rule.

- [ ] Confirm with `udevadm info --export-db | grep -i ACCEL_MOUNT_MATRIX` that a
      rule matched, then try the other rotations. The four quarter turns are in
      [7-sensors.nix](nix/5-phone/1-system/7-sensors.nix)'s header.
- [ ] Drop `st_lsm6dsx` and the ST hwdb entries once settled — added for a part
      this phone does not have.

## Other Thor items

- [ ] **No on-screen keyboard at the login screen.** The phone cannot be logged
      into without a hardware keyboard or the serial console. Phosh ships
      `squeekboard`, but the greeter enables it separately from the session —
      check whether autologin is masking the problem rather than solving it.
- [ ] **Clevis.** Thor prompts for its passphrase every boot; clevis is off.
      Needs `zfs_passphrase` in `secrets/5-phone/clevis.yaml` **identical** to
      `thor_encryption_key`, then `rebind-clevis`, then `enable = true` in
      [9-clevis.nix](nix/5-phone/1-system/9-clevis.nix). Note it only unlocks
      where tang is reachable and Odin's session is unlocked.
- [ ] **Unlock story more broadly.** The initrd USB gadget cannot work without the
      ANX7688 driver, so clevis-over-USB is dead as designed.
      [10-initrd-usb-gadget.nix](nix/5-phone/1-system/10-initrd-usb-gadget.nix)
      and [19-thor-usb-link.nix](nix/3-laptop/1-system/19-thor-usb-link.nix) are
      both inert. Either drop them or keep them dormant pending the kernel change.
- [ ] **`boot.initrd.network.enable`.** initrd SSH is enabled but unusable
      without it, so a stuck boot needs the serial console.
- [ ] **Camera.** Drivers exist but mainline PinePhone support is poor and needs
      app-side work. A project, not a setting.

## Deploying to an offline Thor

Until WiFi works, deploys go through Tow-Boot USB mass storage: expose the eMMC,
unlock the pool on Odin, `nix copy` the closure in, then
`switch-to-configuration boot` under `nixos-enter`. No wipe involved. Two things
that make UMS work, both learned the hard way:

- **Take the phone out of the keyboard case.** The case supplies 5V over the pogo
  pins, which stops the USB-C port entering peripheral mode. Tow-Boot reports
  `Allwinner mUSB OTG (Peripheral)` while the host sees nothing.
- **Connect the cable before starting UMS.** Tow-Boot binds the gadget when the
  command starts; attaching a host afterwards does not re-enumerate. Ctrl+C does
  not return to the menu either — it falls through and boots.

Never use `-a` forms while the phone's disk is attached. `zpool export -a`,
`zfs unmount -a` and friends act on Odin's own pools too. Name the pool, and
mount the ESP by device node — see the partlabel collision below.

## Known bugs

- [ ] **Partlabel collision between Odin and Thor.** Odin's fstab resolves
      `/boot` via `/dev/disk/by-partlabel/disk-root-drive-efi`, and Thor's disko
      config produces the *same* partlabel. While the phone's disk is attached the
      symlink is ambiguous — observed resolving to `/dev/sda1` — and Odin's
      `/boot` silently unmounted during the install, so its next bootloader
      install failed. Nothing was damaged, but a bootloader write during that
      window could have gone to the phone's ESP.

      Fix by giving each host a distinct partlabel, or by having `install-local`
      assert `/boot` is still the local ESP after disko runs.
- [ ] **`nixos-anywhere` cannot install a PinePhone.** postmarketOS has no
      `kexec_load`; the generic NixOS installer has no working network. Recorded
      in [docs/thor.md](docs/thor.md#installing); `install-local` exists because
      of it.
- [ ] **`RESET_GPIO` upstream fix** is still an unmerged RFC. Recheck on kernel
      bumps.

## Network-wide

- [ ] **`nix flake update nixtool`.** The lock is pinned to `7e0ff63a`, which
      predates the SSH-key newline fix and the build-before-partition reordering.
      Both are pushed but not locked here, so Odin's installed `nixtool` would
      still write host keys without the trailing newline.
- [ ] **Ragnarok's clock does not survive a reboot.** It has no RTC battery and
      depends on NTP. Fixed for now by opening udp/123 on Heimdall, but confirm
      it syncs on its own after a cold boot — a wrong clock breaks TLS to the
      binary cache and makes it build everything from source.

## Reference — resolved

Kept so the same ground is not re-covered.

| Symptom | Cause |
| --- | --- |
| Serial garbage at every baud | Two readers on one port, not a baud mismatch |
| `nixos-anywhere` kexec failed | postmarketOS kernel has no `kexec_load` |
| Every aarch64 builder exited 255 | binfmt registered `P` not `PF`; interpreter invisible inside the chroot |
| `zpool` aborted under qemu | disko script built for aarch64; ZFS ioctls cross an ABI |
| disko found a pool that "already exists" | `wipefs` on the disk leaves ZFS labels inside partitions |
| sshd: `invalid format` | OpenSSH needs a trailing newline after the PEM footer |
| Install died mid-copy | USB disk dropped; ZFS suspended the pool, only a reboot cleared it |
| Clients never synced time | FTL advertises itself as NTP via DHCP but udp/123 was closed, and timesyncd never falls back once a server is configured |
| Tow-Boot UMS invisible to host | Keyboard case attached; its 5V on the pogo pins blocks peripheral mode |
