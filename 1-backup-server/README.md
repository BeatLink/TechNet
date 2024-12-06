# Ragnarok

Ragnarok is a single board computer based backup server installed offsite to backup all data in the TechNet.

## Hardware

### Specifications
- Model: Pine64 ROCK64
- Processor: Rockchip RK3328 Quad-Core ARM Cortex A53 64-Bit Processor
- RAM: 2 GB
- Storage: 
    - NixOS         - 128GB MicroSD Card
    - Backup Drive  - 5TB 2.5in SATA HDD

### Links
- https://pine64.com/product/rock64-2gb-single-board-computer/
- https://wiki.pine64.org/wiki/ROCK64
- https://wiki.pine64.org/wiki/ROCK64_Software_Releases


## NixOS

### Notes
- Rock64 may not function with direct connection to certain monitors. Utilize a Xtech HDMI to VGA adapter to bypass this
- SD card images are built within the Nix Flake. 
- Do not upgrade from NixOS-23.11. A regression will prevent booting on the Rock64

### Installation
Run [./scripts/install.sh](./scripts/install.sh) from this folder