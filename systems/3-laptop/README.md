# Odin

# build unatttended installer
  # add command to move ssh keys from iso to /etc/ssh
# Extract built iso
# add ssh keys
# isntall

Odin is a gaming laptop that acts as my daily driver. 

Odin uses NixOS as its main operating system with software installed via FlatPak. The root filesystem is on an encrypted 256GB M.2 NVMe Drive while files and settings for all applications are stored on an encrypted 1TB M.2 NVMe Drive

## Hardware

### Specifications
- Brand: Lenovo
- Model: IdeaPad Gaming 3 15ACH6
- Screen: 15.6" 1920x1080 @ 120Hz
- Processor: AMD Ryzen 5 5600H with Radeon Graphics
- Graphics: NVIDIA® GeForce RTX™ 3050 Ti 4GB 
- RAM: 16 GB
- Storage: 
    - NixOS             - 256GB M.2 2242 NVMe SSD
    - Data Drive        - 1TB M.2 2242 NVMe SSD
- Serial Number: See KeePassXC
- Ethernet MAC: See KeePassXC

* External Drives
    * Windows OS    - 1TB 2.5in USB SATA SSD
    * Data Drive    - 1TB 2.5in USB SATA HDD
    * ISO Drive     - 120GB 2.5in USB SATA SSD
    * Misc Drive    - 64GB M.2 2280 SATA SSD

### Support Links
- [Main Page](https://www.lenovo.com/us/en/p/laptops/ideapad/ideapad-gaming-laptops/gaming-3-gen-6-(15-amd)/wmd00000479)
- [Support Site](https://pcsupport.lenovo.com/us/en/products/laptops-and-netbooks/gaming-series/ideapad-gaming-3-15ach6/82k2/82k201xcus)
- [Hardware Manual](https://download.lenovo.com/consumer/mobiles_pub/ideapad_gaming3_hmm_v1.1.pdf)


## UEFI Settings 

### Information
* Nothing to Do

### Configuration
| Setting                       | Value                 |
| ---                           | ---                   |
| System Time                   | Leave Default         |
| System Date                   | Leave Default         |
| Wireless LAN                  | Enabled               |
| SATA Controller Mode          | AHCI                  |
| Graphics Device               | Switchable Graphics   |
| UMA Frame Buffer Size         | 2G                    |
| AMD V Technology              | Enabled               |  
| BIOS Back Flash               | Disabled              |
| Hotkey Mode                   | Enabled               |
| Fool Proof Fn Ctrl            | Enabled               |
| Flip to Boot                  | Enabled               |
| Restore Default Overclocking  | Disabled              |
| Disable Built In Battery      | Ignore                |


## Security
| Setting                       | Value                 |
| ---                           | ---                   |
| Administrator Password        | Not Set               |
| User Password                 | Not Set               |
| HDD Password                  | Not Set               |
| AMD PSP                       | Enabled               |
| Clear AMD PSP Key             | Ignore                |
| Device Guard                  | Disabled              |
| Secure Boot                   | Disabled              |
| Reset to Setup Mode           | Ignore                |
| Restore Factory Keys          | Ignore                |

## Boot
| USB Boot                      | Enabled               |
| PXE Boot to LAN               | Disabled              |
| IPv4 PXE First                | Enabled               |
| EFI                           | NixOS first           |


