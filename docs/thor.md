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

The kernel is megi's tree, built by nixpkgs' `linuxManualConfig` from source,
config and patches borrowed out of mobile-nixos' device directory —
see [`13-kernel.nix`](../nix/5-phone/1-system/13-kernel.nix) for why its own
`kernel-builder` cannot be used. The short version: that builder deletes the
kernel build tree, and ZFS is an out-of-tree module.

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

## Recovering a deeply discharged battery

The radios run off the battery rail, not off USB — `vmmc-supply = <&reg_vbat_wifi>`
— so a flat cell means no WiFi, no Bluetooth and no modem however well the
software is configured. Pine64 say the same: those parts "do not work without a
battery and with a drained battery, even when enough power is supplied via the
USB Type-C port".

A cell that has fallen far enough looks alarmingly like a dead one. At 0.13V the
gauge reported `capacity 0`, `current_now 0` and a voltage that drifted around in
a ~30mV band for over an hour across five different power sources. That is not
proof of a dead pack, and it is worth not concluding so — it recovered.

### The short version

1. Install postmarketOS, or anything else running a megi kernel.
2. Start the phone up with the charger already connected.
3. Leave it for a few hours.

That is the whole procedure now. Everything below this is why it works and what
was needed before the kernel was right — the elaborate JumpDrive dance in
[What actually helped](#what-actually-helped) was working around mainline
refusing to charge at all, which
[13-kernel.nix](../nix/5-phone/1-system/13-kernel.nix) has since settled.

Do **not** improvise a charger. USB is 5V against a 4.2V maximum with no current
limit, and a cell that has sat at 0.13V is the highest-risk case there is. A
bench supply at ~4.0V with a 50–100mA limit is the legitimate version; a NiMH
charger such as the BQ-CC65 is the wrong chemistry entirely.

### How the AXP803 charger works

Sources: the [AXP803 datasheet](https://files.pine64.org/doc/datasheet/pine64/AXP803_Datasheet_V1.0.pdf)
(§9.4, and the register map) and the [PinePhone v1.2 schematic](https://files.pine64.org/doc/PinePhone/PinePhone%20v1.2%20Released%20Schematic.pdf)
(page 06, PMIC).

The PMIC sits on the sunxi RSB bus at 0x3a3, and every register below is readable
on a running system:

    sudo cat /sys/kernel/debug/regmap/sunxi-rsb-3a3/registers

Charging runs as a three-stage profile, all of it in hardware — the kernel
configures it and reads it back, but does not drive it:

| Stage | Entry | Current |
| --- | --- | --- |
| Trickle / pre-charge | VBAT < `VTRKL`, fixed at **3.0V** | `ITRKL`, fixed at **10% of ICHRG** = 120mA |
| Constant current | VBAT > 3.0V | `ICHRG`, REG 33H[3:0] — 1200mA |
| Constant voltage | VBAT near `VTRGT` | tapering |
| Done | VBAT > VTRGT-0.1V **and** I < 10% ICHRG | 0 |

Two safety timers cap it (REG 34H): pre-charge 50 minutes, fast charge 8 hours.
On expiry the charger drops into **safe mode**, which trickles a fixed **5mA**
until the pack reaches VTRGT-0.1V. Safe mode is reported in REG 01H[3]. The timer
holds while charge current is under 20% of ICHRG, so a slow charge does not itself
trip it.

Separately, and this is the part that bites: the pack's **NTC thermistor is wired
to the PMIC's TS pin** and gates charging entirely. The schematic confirms it is
a real sensor rather than a stand-in — J600 pin 3 (`TS`) reaches the AXP803
through R630, a 0R link, and the note on page 06 reads *"IF use the battery
temperature sensor: A=NC, otherwise: A=10k"* with R603 fitted **NC**. So there is
no 10k substitute resistor: what the PMIC measures is the cell's own thermistor.

    REG 38H  VLTF-charge   A5H   2.112V    under-temperature limit
    REG 39H  VHTF-charge   1FH   0.397V    over-temperature limit
    REG 58H/59H            TS pin ADC, 12-bit, 0.8mV per LSB
    REG 84H[1:0]           10 = protection active when charging and discharging

The NTC is a negative-tempco part, so **hot reads low**. Datasheet Table 9-27
gives 0.467V at 40°C, 0.394V at 45°C, 0.284V at 55°C. Anything below `VHTF`
counts as over temperature, and §9.4 is explicit about the consequence: *"charger
will stop charging and REG 01H[6] change to 0 to reflect the status."*

Those three rows also calibrate the pin, which makes it far more useful than a
temperature reading. Dividing voltage by resistance gives 79.97, 80.02 and
80.00µA — **the TS current source is 80µA**, so the ADC is an ohmmeter:

    R(ohms) = TS(volts) / 80e-6      or      R = LSB * 10

No multimeter required, which matters because the pack has to be in the phone to
be measured at all. For reference, the OTP limit of 0.397V is **5.0k**.

**The PinePhone's pack uses a 3k NTC, not the 10k the AXP803's defaults assume.**
That single fact is the whole bug, and it is documented only in megi's kernel,
where the PinePhone thermal block spells the curve out in ohms:

    Charging:
      0 - 15 °C:  9750 Ohm - 4710 Ohm
     15 - 50 °C:  4710 Ohm - 1080 Ohm
    Discharging:
    -10 °C : 16500 Ohm      55 °C : 896 Ohm

### What Thor's PMIC actually reports

    00: f7    VBUS present and valid; VBAT < 3.5V; direction = charging
    01: 30    bit6=0 NOT CHARGING; bit5/4 battery present and valid; bit3=0 not safe mode
    33: c5    charger enabled, 4.2V target, 1200mA  (the default, nothing misconfigured)
    34: 45    pre-charge timer 50 min, fast charge 8h  (also default)
    39: 1f    over-temperature limit 0.397V
    58: 0b  59: 03    TS = 0x0B3 = 179 LSB = 143mV

**143mV against a 397mV limit**, so the PMIC refuses to charge. 143mV is 1.8k,
and against the 3k curve above that interpolates to **about 38°C** — an entirely
normal temperature for a phone that has been running. The pack is fine. The
threshold is simply wrong for it, because 5.0k is where a 10k NTC would sit at
roughly 45°C and where a 3k NTC never sits at all outside of freezing.

That single fact explains the rest. REG 01H[6] reads 0 exactly as the datasheet
says it should, the charger is enabled and correctly configured but not charging,
and the "pulsing" seen on the console — voltage cycling through three repeating
values, current alternating 5/7/10mA — is the charger retrying and being cut off
again, against the 57.6mV hysteresis the datasheet specifies for the OTP
threshold.

The driver's `health` attribute says `Good`, which does **not** contradict this:
mainline `axp20x_battery` derives health from REG 01H[7], the PMIC *die*
temperature, and never looks at the pack's TS reading.

The thermistor is **live and accurate**, established by putting a bag of frozen
peas on the pack and watching the ADC: TS rose from 180 to 222 LSB, the right
direction for a negative-tempco part. In ohms that is 1.8k → 2.2k, which on the 3k
curve is 38°C → 33°C. A 5°C drop from surface cooling through the back cover, and
it agrees with the independent B-value estimate. Nothing about the pack is faulty.

An earlier reading of this evidence recorded here — that the NTC was the wrong
value or shunted by corrosion — was wrong, and came entirely from assuming a 10k
part. The measurements were right; the reference was not. It is worth not
replacing a healthy battery on the strength of it.

### Why mainline cannot charge this phone

Nothing sets the thresholds for the actual hardware. The AXP803 powers up with
VHTF at 1FH, tuned for a 10k NTC, and mainline's `axp20x_battery` never
reprograms it on the PinePhone — the driver's only temperature handling is in
`axp717_set_battery_info()`, for a different PMIC. So a healthy 3k NTC at any
ordinary room temperature reads as over-temperature and charging is refused.

megi's tree fixes it, guarded on `of_machine_is_compatible("pine64,pinephone-1.2")`:

    regmap_write(regmap, 0x38,  9750 * 80 / 12800);  // V_LTF-charge
    regmap_write(regmap, 0x39,  1080 * 80 / 12800);  // V_HTF-charge
    regmap_update_bits(regmap, 0x84, 0x37, 0x31);    // TS pin only when charging

The `* 80 / 12800` is the 80µA current source and the 12.8mV-per-LSB register
step, so those constants are resistances in ohms. `1080 * 80 / 12800` truncates to
6, which is 76.8mV, or **960 ohms** — comfortably under the 1.8k the pack reads,
so charging proceeds.

That is the fix. It needs no patch and no hardware change: the kernel in
[13-kernel.nix](../nix/5-phone/1-system/13-kernel.nix) already carries it.

**Confirmed on hardware.** Booting postmarketOS from an SD card — same megi tree,
eMMC untouched — produced:

    [0.724851] axp20x-battery-power-supply: Configuring battery thermal regulation for Pinephone
    status Charging   current_now 1312000   voltage_now 3573900   health Good

1.3A, against 5-11mA and a voltage stuck at 2.9V all day under mainline. The cell
took the current immediately, which settles that it was never the problem.

Worth keeping as a recovery trick: REG 39H resets only on a genuine power-on
reset, and mainline never writes it, so **booting any megi-based system once
leaves the threshold corrected for mainline too**. A 30-second postmarketOS boot
from SD unblocks charging on the installed NixOS until the pack is disconnected or
run flat.

Two things follow. Do **not** add `x-powers,no-thermistor` handling to the AXP803
path to force charging — it would disable a protection megi has configured
correctly for this exact battery, on a phone whose pack has been deeply
discharged, which is when thermal limits matter most. And a 10k resistor across
the TS contacts would be wrong for the same reason.

Overriding the threshold needs a kernel change, because
`/sys/kernel/debug/regmap/sunxi-rsb-3a3/registers` is mode `-r--------`. That is
**not** a Kconfig option that happens to be off — `regmap-debugfs.c` reads

    #undef REGMAP_ALLOW_WRITE_DEBUGFS
    #ifdef REGMAP_ALLOW_WRITE_DEBUGFS

with a comment that there is deliberately *"no real compile time configuration
option for this feature, people who want to use this will need to modify the
source code directly"*, and singling out PMICs as the reason. The `#undef` sits
above the guard, so `-D` on the command line is discarded before it is read. The
same symbol picks 0600 over 0400 for the `registers` file further down.

[13-kernel.nix](../nix/5-phone/1-system/13-kernel.nix) flips it to `#define` with
a `substituteInPlace --replace-fail`, so the build breaks loudly if that line ever
moves. Once the megi kernel is running, REG 39H and REG 84H become writable and
the thermistor threshold is testable without a rebuild per attempt.

### What the readings mean

    status       Charging      claims charging
    current_now  0             but nothing is flowing
    voltage_now  126000        0.13V, against a 2.9V minimum

`voltage_min` is 2.9V and `voltage_max` 4.2V, so anything under 2.9V is below the
charger's threshold. Below that the AXP803 sits in **pre-charge**, trickling a
few milliamps deliberately: pushing real current into a deeply discharged lithium
cell is how fires start. `constant_charge_current` is 1.2A, but none of that is
used until the cell crosses roughly 3.0V.

The gauge reads `capacity 0` and `energy-full 0 Wh` throughout, because it cannot
characterise a pack it has never seen at a plausible voltage. Ignore both until
the voltage is sensible.

### What actually helped

Recovery came from cutting the phone's own draw until the trickle got ahead:

1. **Boot JumpDrive from an SD card** rather than the installed system. It is a
   minimal initramfs, so the phone draws very little, and it never reaches a
   heavy phase to brown out on. Note its kernel has no `axp20x_battery`, no
   `/lib/modules` and no `modprobe`, so the gauge cannot be read from there —
   charge first, measure afterwards.
2. **Remove the SD card, detach the keyboard dock, and switch off the DIP
   switches** for the radios. Fewer subsystems powered means more of the input
   reaches the cell.
3. **Use a lower-wattage supply if it is stuck in a boot loop.** The phone powers
   on whenever external power appears; from a flat cell it browns out within a
   second and retries, and each attempt burns more than the trickle delivers. A
   weaker source can fail to trigger the power-on at all, letting charge
   accumulate.

Watch progress on the serial console: each boot attempt reaching a later stage —
SPL, then U-Boot, then the menu, then the kernel — is the charge climbing.

### What did not help

Stopping the graphical session and blanking the display moved charge current from
7mA to 5mA, which is to say nothing at all. Pre-charge is a state machine keyed
on cell voltage, not a power budget, so reducing load once the system is idle
changes nothing. Only crossing ~3.0V does.

### Monitoring

    cat > /tmp/batt <<'EOF'
    B=/sys/class/power_supply/axp20x-battery
    V=$(cat $B/voltage_now); I=$(cat $B/current_now)
    echo "state    $(cat $B/status)   capacity $(cat $B/capacity)%"
    awk -v v=$V -v i=$I 'BEGIN{printf "voltage  %.3f V\ncurrent  %.0f mA\n", v/1000000, i/1000}'
    date "+checked   %H:%M:%S"
    EOF
    watch -n5 sh /tmp/batt

Take the trend from several readings minutes apart. A single sample is unreliable
— the SoC draws from the same rail, so the voltage sags and recovers, and one
high reading is not progress.

### Supply limits

    usb_type  Unknown [SDP] DCP CDP

The bracketed entry is what was detected. **SDP** is an ordinary USB port and caps
at 500mA — that is what a laptop gives. **DCP** is a wall charger, 1.5A or more.
`input_current_limit` reads 3A but that is only the PMIC's ceiling, not what it
will draw.

This does not matter during pre-charge, where only milliamps flow. It matters
immediately afterwards, when the target becomes 1.2A and a 500mA port halves the
rate. USB-PD would lift this, but PD needs the ANX7688 driver that mainline does
not have — which is why detection falls back to BC1.2 heuristics in the first
place.

### Turning the display off

Useful for leaving the phone somewhere, though as noted it does not speed up
charging:

    sudo systemctl isolate multi-user.target
    echo 0 | sudo tee /sys/class/backlight/backlight/brightness
    echo 4 | sudo tee /sys/class/backlight/backlight/bl_power
    echo 0 | sudo tee /sys/class/vtconsole/vtcon1/bind

The brightness write silently fails while phosh is running — it resets it — so
stop the session first and check `actual_brightness` afterwards rather than
assuming. The last line unbinds the framebuffer console, which is what leaves a
blinking cursor on the panel even after blanking. `systemctl isolate
graphical.target` puts it all back.

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
