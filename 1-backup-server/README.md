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
- Instructions are generated from here https://nixos.wiki/wiki/NixOS_on_ARM/PINE64_ROCK64#Status

### Installation
1. Flash the SPI by following this link https://wiki.pine64.org/wiki/Getting_started#Flashing_u-boot_to_SPI_Flash
2. Download NixOS 64-bit ARM SD Card image from https://nixos.wiki/wiki/NixOS_on_ARM#Installation
3. Extract and flash the image using Etcher
4. Download u-boot-rockchip.bin from https://hydra.nixos.org/job/nixpkgs/trunk/ubootRock64v2.aarch64-linux
5. Flash the binary using the below commands. Replace mmcblkX with the path to the sd card
    ```bash
    sudo dd if=u-boot-rockchip.bin of=/dev/mmcblkX seek=64 && sync
    ```
6. Execute the below commands
    ```bash
        sudo sed -i 's/loglevel=7/loglevel=7 video=HDMI-A-1:1920x1080@60/g' /media/beatlink/NIXOS_SD/boot/extlinux/extlinux.conf
        sudo sed -i 's/TIMEOUT 50/TIMEOUT 5/g' /media/beatlink/NIXOS_SD/boot/extlinux/extlinux.conf
        
    ```
7. Insert the SD card and boot. Note that it may take several minutes for anything to be displayed
4. On the login screen, set an initial password by running `passwd`
5. Get the IP address of the server by running ifconfig
5. SSH into the server by running `ssh nixos@<ip-address>`
6. Generate the system configuration by running `sudo nixos-generate-config`
6. Copy the backup server file by running `scp ./backup-server-config.nix nixos@<ip-address>:/home/nixos`
7. Install the configuration file by running `sudo mv /home/nixos/backup-server-config.nix /etc/nixos/configuration.nix`
8. Run `sudo nixos-rebuild switch` to load your custom changes
