# Odin — fans

Odin is a Lenovo IdeaPad Gaming 3 15ACH6 (`82K2`, BIOS `H3CN49WW`). Its fans
are driven by the embedded controller (EC) over ACPI, and Linux sees none of
them: there is no `fan*_input` under `/sys/class/hwmon`, so Mission Center's fan
view stays empty.

## What was tried

**`sensors-detect --auto`** — the step Mission Center's "Enabling Additional
Values" script runs for fans — reports *"no sensors were detected … relatively
common on laptops, where thermal management is handled by ACPI"*. There is no
Super I/O chip to load a driver for, so lm_sensors has nothing to offer.

**[LenovoLegionLinux](https://github.com/johnfanv2/LenovoLegionLinux)**
(`linuxPackages.lenovo-legion-module`, `lenovo-legion` in nixpkgs) does
recognise this laptop. The driver picks its per-model config by the first four
characters of the BIOS version, and `H3CN` maps to `model_h3cn`, labelled
"Ideapad Gaming 3 15ACH6". What that config enables:

| Feature | H3CN | Why |
| --- | --- | --- |
| Fan speed (RPM) | No | Not implemented in ACPI, and the WMI method returns a constant 0 |
| Fan curve | No | No access method |
| Fan full speed on/off | Yes | WMI |
| Temperatures | Yes | WMI |
| Power mode | Yes | WMI, but no custom mode |
| Keyboard RGB | No | Controlled over USB, not the EC |

So the module would give a max-fan toggle and nothing more. It still would not
fill Mission Center's fan view, which needs an RPM reading. Power-mode switching
is likely already covered by `ideapad_laptop`. The model is also absent from the
project's tested list, which is mostly Legions.

## Firmware

UEFI is no obstacle. Secure Boot is disabled, so an out-of-tree module loads
unsigned; turning Secure Boot on would mean signing it.

## Where this leaves it

Not installed. The only real fan curve on this machine would mean writing the
EC's registers directly — the driver knows where they are
(`memoryio_physical_ec_start = 0xC400`) but deliberately leaves curves disabled
on this model, and untested EC writes are not worth the risk to the hardware.
Revisit if a newer LenovoLegionLinux enables fan speed or curves for `H3CN`.
