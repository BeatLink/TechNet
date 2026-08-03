# TODO

Outstanding work, most blocking first. Background for the Thor items is in
[docs/thor.md](docs/thor.md).

## RESOLVED — the battery charges; the pack was never faulty

Confirmed on hardware by booting postmarketOS from SD, which ships the same megi
kernel. It charges at **1.3A**:

    [0.724851] axp20x-battery-power-supply: Configuring battery thermal regulation for Pinephone
    status Charging   current_now 1312000   voltage_now 3573900   health Good

Against 5-11mA and a stuck 2.9V under mainline. Voltage moved 2.902 -> 3.443 ->
3.574V within minutes. Kept below for the reasoning, because the same trap catches
every mainline-based distro on this hardware.

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

**Root cause found in the PMIC registers: the charger is being blocked by battery
over-temperature protection.** Full working in
[docs/thor.md](docs/thor.md#how-the-axp803-charger-works).

The pack's NTC thermistor gates charging, and the PinePhone wires it for real —
schematic page 06 fits R603 as `NC`, so there is no 10k stand-in resistor. The
AXP803 reads the cell's own thermistor on its TS pin, and:

    39: 1f              over-temperature limit  VHTF = 0.397V
    58: 0b  59: 03      TS pin ADC = 179 LSB    = 0.143V
    01: 30              bit6 = 0                charger NOT charging
    33: c5              charger enabled, 4.2V, 1200mA -- correctly configured

Datasheet §9.4: over temperature means *"charger will stop charging and REG 01H[6]
change to 0"* — exactly what REG 01H reports. The pulsing on the console is the
charger retrying against the OTP hysteresis. Nothing is misconfigured, and input
current is not the constraint: under JumpDrive the PMIC offers 1.5A and nothing
takes it.

No multimeter is needed to measure the thermistor — the TS pin's current source is
**80µA**, derived from three datasheet rows agreeing to within 0.05%, so the ADC
*is* an ohmmeter: `R = LSB * 10`. That matters because the pack has to be in the
phone to be measured at all.

**Why the threshold is wrong: the PinePhone's pack has a 3k NTC, and the AXP803's
power-on defaults assume 10k.** Documented only in megi's kernel, which carries
the curve in ohms — 4710R at 15°C down to 1080R at 50°C. Against that, the pack's
measured 1.8k is **≈38°C**, and 2.2k under frozen peas is ≈33°C: a healthy sensor
reading a real temperature, on a phone that had been running. The 5.0k limit is
where a *10k* NTC sits at ~45°C and where a 3k NTC never sits at all.

Mainline never reprograms it — `axp20x_battery`'s only temperature handling is in
`axp717_set_battery_info()`, for a different PMIC — so mainline simply cannot
charge a PinePhone whose battery is above about 10°C.

**megi's kernel fixes this with no patch and no hardware change**, guarded on
`of_machine_is_compatible("pine64,pinephone-1.2")`:

    regmap_write(regmap, 0x39, 1080 * 80 / 12800);  // -> 6 -> 76.8mV -> 960 ohms

960R is comfortably below the pack's 1.8k, so charging proceeds.

Two earlier conclusions recorded here were wrong and are corrected above: that the
cell was dead, and that the NTC was the wrong value or shunted by corrosion. Both
came from assuming a 10k thermistor. **Do not replace the battery or clean
contacts on the strength of them** — the pack is healthy.

- [x] **Boot a megi kernel and confirm it charges.** Done via postmarketOS on SD —
      1.3A on a DCP wall charger. The eMMC install was untouched.
- [ ] **The threshold persists in the PMIC**, since REG 39H resets only on a true
      power-on reset and mainline never writes it. So NixOS on its current
      mainline kernel will keep charging after a reboot, until the pack is
      disconnected or run flat. Useful as a stopgap; not a substitute for the
      megi kernel, which sets it on every boot.
- [ ] Do **not** add `x-powers,no-thermistor` handling to the AXP803 path, and do
      not fit a 10k resistor across the TS contacts. Both force charging by
      disabling a protection megi configures correctly for this battery — on a
      pack that has been deeply discharged, which is when thermal limits matter
      most. The regmap-debugfs write in
      [13-kernel.nix](nix/5-phone/1-system/13-kernel.nix) stays as a diagnostic,
      not as the fix.

### Recovering a deeply discharged pack

Kept for the recovery procedure only, since the same trap catches every
mainline-based distro on this hardware: a deeply discharged pack sits below the
AXP803's ~3.0V pre-charge threshold and trickles at a few mA, which looks
identical to the fault above. Booting JumpDrive from SD is the best case the
phone can offer while recovering — 1.5A available and near-zero draw, and it
sidesteps the auto-boot loop that burns the trickle. Its kernel has no
`axp20x_battery` and no `modprobe`, so progress is only readable by booting
something else afterwards.

Do **not** improvise a charger. USB is 5V against a 4.2V maximum with no current
limit, and a cell that has sat at 0.13V is the highest-risk case there is. A
bench supply at ~4.0V with a 50–100mA limit is the legitimate version; a NiMH
charger such as the BQ-CC65 is the wrong chemistry entirely.

## Done — Thor runs megi's kernel

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

[13-kernel.nix](nix/5-phone/1-system/13-kernel.nix) now builds megi's tree with
**nixpkgs' `linuxManualConfig`**, taking only the source, config and patches from
mobile-nixos' device directory rather than its `kernel-builder`.

That builder turned out to be unusable here, and it would have been regardless of
these changes: its `postInstall` deletes `lib/modules/*/build` and
`lib/modules/*/source` and it produces no `dev` output, so there is **no build
tree to compile out-of-tree modules against**. Fine for a phone with everything
built in; fatal for Thor, whose root is ZFS. It also omits `features`, `config`
and `commonMakeFlags`, all of which NixOS reads at evaluation time — each one
surfacing only as the next error after the last was shimmed. `linuxManualConfig`
supplies all of it, so the shims are gone.

Two local changes ride on top:

| Change | Why |
| --- | --- |
| `#undef` → `#define REGMAP_ALLOW_WRITE_DEBUGFS` | writable PMIC registers, for the thermistor threshold above |
| `CONFIG_EFI=y`, `CONFIG_EFI_STUB=y` | megi ships `# CONFIG_EFI is not set`, which suits the extlinux boot postmarketOS uses; Thor goes through Tow-Boot UEFI into systemd-boot, which loads the kernel as an EFI application |

The EFI options are appended to a generated copy of megi's config, where Kconfig's
last-assignment-wins rule overrides the earlier `is not set`. Because `oldconfig`
drops options with unmet dependencies *silently*, the result is asserted in
`postConfigure` — a wrong guess costs two minutes rather than a full build.
`features.efiBootStub` is declared alongside, since systemd-boot asserts on it
separately and the two must agree.

Verified by evaluation: Thor's `system.build.toplevel` evaluates, the kernel now
has a `dev` output, and `zfs_2_4` reports `broken = false` against 6.17 (ZFS 2.4.3
supports up to 7.0).

- [x] **Build it.** Not in any binary cache, so this is a full aarch64 kernel
      build plus ZFS against it. Ragnarok is the only native aarch64 host but has
      2GB of RAM;
      [9-remote-builder.nix](nix/1-backup-server/1-system/9-remote-builder.nix)
      now pins `nix.settings.cores = 2` so make does not run four compilers into
      the OOM killer. Two things make 2GB more plausible than it sounds: megi's
      config sets `CONFIG_DEBUG_INFO_NONE`, which is the single largest saving in
      both memory and disk, and zram is already on from
      [3-memory-management.nix](nix/0-common/1-system/4-core/3-memory-management.nix)
      — build memory is anonymous and compresses well. Fallback if it still will
      not fit: build on Odin under binfmt, correct but hours slower.
- [ ] **Ragnarok is currently unreachable** — `ssh: connect to host
      ragnarok.technet port 22: Connection timed out`, and a test build fell back
      to local emulation. Bring it up before starting, or the kernel builds under
      qemu by default without saying so.
- [ ] Confirm `/sys/kernel/debug/regmap/sunxi-rsb-3a3/registers` comes up `0600`
      afterwards, then try REG 39H before doing anything physical to the battery.
- [ ] Recheck what is still needed once it boots — the USB gadget, DisplayPort,
      keyboard DT node and WiFi items were all expected to be settled by this
      kernel rather than by patching mainline separately.

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

## Keyboard accessory — should work now, untested

Under mainline this needed a hand-written device tree node. Instantiating the
device over i2c got as far as an input device and then died:

    echo pinephone-keyboard 0x15 > /sys/bus/i2c/devices/i2c-2/new_device
    pinephone-keyboard 2-0015: Failed to request IRQ: -22

`new_device` supplies a bus and an address but not an interrupt, and an interrupt
can only come from DT.

megi's tree has the node already, complete with the interrupt, and the case's
IP5209 nested behind the keyboard's own i2c passthrough — which is why
`ip5xxx_power` could never bind while the keyboard driver failed to probe:

    ppkb: keyboard@15 {
        compatible = "pine64,pinephone-keyboard";
        interrupt-parent = <&r_pio>;
        interrupts = <0 12 IRQ_TYPE_EDGE_FALLING>;  /* PL12 */
        i2c { charger@75 { compatible = "injoinic,ip5209"; ... }; };
    };

What was missing was the driver, not the description: mobile-nixos' config had
`# CONFIG_KEYBOARD_PINEPHONE is not set`, so the hardware was fully described and
nothing bound to it. Now enabled in PinePhoneKernel.

- [ ] **Test it.** Attach the case and check `dmesg | grep -i ppkb`, that keys
      reach userspace, and that the case battery appears as a second entry under
      `/sys/class/power_supply`. No DT patching should be needed.

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

## Next up on Thor

The phone is deployed and running megi's kernel. These are the things standing
between it and being usable without a serial cable, roughly in order.

- [ ] **Deploy clevis.** Thor prompts for its passphrase on every boot and clevis
      is off. Needs `zfs_passphrase` in `secrets/5-phone/clevis.yaml`
      **identical** to `thor_encryption_key`, then `sudo rebind-clevis` on the
      phone with tang reachable, then `enable = true` in
      [9-clevis.nix](nix/5-phone/1-system/9-clevis.nix) and a rebuild. It is
      disabled during install on purpose: `boot.initrd.clevis.devices` reads the
      JWE at **build** time, so it cannot exist before the first boot.

      Note what this does and does not buy. It only unlocks where tang is
      reachable **and** Odin's session is unlocked, so away from home the phone
      still prompts — which is the whole reason the next two items matter.
- [ ] **Plymouth and graphical decryption.** The passphrase prompt is currently
      a bare console on a device with no keyboard attached. Plymouth's password
      prompt is what makes it enterable on a touchscreen at all, and
      [nixos-plymouth](flake.nix) is already a flake input used elsewhere on the
      network. Needs the initrd to bring up the DSI panel — check whether the
      display comes up early enough in stage 1, since that is the part most
      likely not to work.
- [ ] **On-screen keyboard at the greeter.** Even past decryption the phone
      cannot be logged into without a hardware keyboard or the serial console.
      Phosh ships `squeekboard`, but the greeter enables it separately from the
      session — check whether autologin is masking the problem rather than
      solving it.
- [ ] **Watch phosh's restart count after the reboot.** It reached
      `NRestarts=6` while LightDM held /dev/dri/card1 — phosh has
      `Restart=always`, so it crash-looped against the greeter rather than
      failing outright. With the display manager removed it should settle at 0.
      If it keeps climbing, the problem is phosh itself and not the greeter.
- [ ] **Test the keyboard accessory** — see [above](#keyboard-accessory--should-work-now-untested).
      If it works it also sidesteps the two items above, since the case provides
      a real keyboard for both the passphrase prompt and the greeter.

## Other Thor items

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

- [ ] **The remote builder has never worked — the key path does not exist.**
      [21-remote-builder.nix](nix/3-laptop/1-system/21-remote-builder.nix) points
      `sshKey` at `/persistent/etc/ssh/ssh_host_ed25519_key`, and that file is
      not there on Odin. Reproduced exactly as the daemon runs it:

          # ssh -i /persistent/etc/ssh/ssh_host_ed25519_key beatlink@ragnarok.technet
          Warning: Identity file ... not accessible: No such file or directory
          beatlink@ragnarok.technet: Permission denied (publickey).

      So every aarch64 build has silently fallen back to emulation on Odin. It
      shows up in build logs as one line that is easy to read past:

          cannot build on 'ssh-ng://beatlink@ragnarok.technet':
          error: failed to start SSH connection

      Ragnarok was reachable the whole time — up since 10:22, answering
      interactive ssh as beatlink. It is the daemon's key, not the host.

      Find where Odin's host key actually lives (`/etc/ssh/ssh_host_ed25519_key`
      is also absent, so check what 4-persistence.nix keeps and what sops uses as
      its age identity) and point `sshKey` at that. Worth doing: it is the
      difference between ~25 minutes and ~10 for a ZFS rebuild, and it was the
      justification for the ARC and cores tuning in
      [9-remote-builder.nix](nix/1-backup-server/1-system/9-remote-builder.nix),
      which has therefore never been exercised.
- [ ] **`zfs-kernel` is the only thing left on the critical path.** The kernel
      now substitutes in seconds, so a nixpkgs bump costs ~25 minutes rebuilding
      the ZFS module against it under emulation. Two ways out, in order of
      preference: fix the remote builder above, or run attic on Heimdall and
      cache Thor's closures privately. Do **not** publish zfs-kernel from
      PinePhoneKernel — the module and userland must be the same ZFS version, and
      coupling a public cache to the consumer's ZFS version breaks root-on-ZFS
      machines rather than merely slowing them down.
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
- [ ] **Ragnarok's clock does not survive a reboot.

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
