# Ragnarok

Ragnarok is a single board computer based backup server installed offsite to backup all data in the TechNet.

## Hardware

### Specifications

- Model: Pine64 ROCK64
- Processor: Rockchip RK3328 Quad-Core ARM Cortex A53 64-Bit Processor
- RAM: 2 GB
- Storage: 
  - NixOS         - 128GB 2.5in SATA USB SSD
  - Backup Drive  - 5TB 2.5in SATA USB HDD

### Links

- https://pine64.com/product/rock64-2gb-single-board-computer/
- https://wiki.pine64.org/wiki/ROCK64
- https://wiki.pine64.org/wiki/ROCK64_Software_Releases

## NixOS

### Notes

- Rock64 may not function with direct connection to certain monitors. Utilize a Xtech HDMI to VGA adapter to bypass this

- For Serial setup:
  - Connect the wires as follows
    - Black - GND
    - White - RXD
    - Bown - TXD
  - 

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
