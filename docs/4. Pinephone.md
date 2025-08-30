# Thor X

Thor X is a PinePhone smartphone that's intended as my alternate phone and experimental mobile computing platform. Hopefully it, or an upgraded version may replace my daily driver.

Odin uses NixOS as its main operating system. The root filesystem is on a zfs encrypted partition on the built in eMMC chip while a 128 GB SD Card holds the TowBoot bootloader partition and an encrypted ZFS data partition for storing files and settings for all applications.

## Hardware

### Specifications

- Brand: Pine64
- Model: PinePhone 3GB RAM 32GB EMMC
- Screen: 5.95″ LCD 1440×720, 18:9 aspect ratio (hardened glass)
- Processor: 4 x ARM Cortex A53 cores @ 1.152 GHz
- Graphics: ARM Mali 400 MP2 GPU
- RAM: 3GB LPDDR3 RAM
- Storage:
  - NixOS             			- 32GB eMMC
  - TowBoot / Data Drive       - 128GM microSD
- Serial Number: See KeePassXC
- Ethernet MAC: See KeePassXC

### Support Links

- [Main Page](https://pine64.org/devices/pinephone/)
- [Support Site](https://wiki.pine64.org/index.php/PinePhone)
- [Hardware Manual](https://pine64.org/documentation/PinePhone/)

### Tow-Boot

The bootloader for Thor X is Tow Boot. As the PinePhone is not equipped with an SPI flash, the Tow-Boot shared disk image is installed to the SD card used for shared storage. This is to allow the device to boot any UEFI aarch64 ISO or drive without specific imaging and structures on the eMMC card.

#### Installation

1. Run [./scripts/flash-sd-card.sh](./scripts/flash-sd-card.sh)

## NixOS

### Notes

- For Serial setup:
  - Open the PinePhone Back Cover
  - Set hardware switch 6 (headphones) to off
  - Connect the USB to 3.5mm UART Cable
  - Start a shell with `nix-shell -p minicom --command "sudo minicom -D /dev/ttyUSB0 -b 115200 --color=on"`
  - Run
  - Power on the phone

### Installation

1. Download the NixOS Minimal Aarch64 ISO
2. Write it to a usb drive
3. Format a fast SSD drive with a linux swap partition using Gparted
4. Disconnect all other drives from the SBC
5. Add the installation drive
6. Boot
7. Connect the root drive and the swap drive after the boot screen loads
8. Run the following commands to set a root password
   ```bash
   sudo -i
   passwd
   ```
9. Run `ifconfig` to get the IP address
10. Run the following to enable the temporary swap

```bash
  swapon /dev/<path-to-swap-partition>
  mount -o remount,size=10G,noatime /nix/.rw-store
```

11. Run [./scripts/install.sh](./scripts/install.sh) from this folder
