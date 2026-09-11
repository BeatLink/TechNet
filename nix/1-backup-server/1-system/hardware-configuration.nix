# Hardware Configuration #############################################################################################################################
#
# The Rock64 board, the drivers it needs before the disks can be unlocked, and the fixes its three USB-to-SATA adapters need to work reliably.
#

{ lib, pkgs, ... }:
let
    # The two adapters the backup drive has been plugged in through
    dataBridges = [
        "0583"
        "0576"
    ];

    # The most the root drive's adapter will erase in one request: it refuses anything above 65535 sectors, and the kernel wants a multiple of 4 KiB
    maxDiscardBytes = toString (8191 * 4096);

    rootBridgeRules = ''
        # Treat the root drive as the SSD it is, and do not use its timing as a source of randomness
        ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="1561", ATTR{queue/rotational}="0", ATTR{queue/add_random}="0"

        # Let the SSD erase unused space, then cap the request size; the cap must come second, and tee is spelled out because early boot has no PATH
        ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="1561", RUN+="/bin/sh -c 'echo unmap | ${pkgs.coreutils}/bin/tee /sys%p/device/scsi_disk/*/provisioning_mode >/dev/null && echo ${maxDiscardBytes} > /sys%p/queue/discard_max_bytes'"
    '';
in
{
    config = lib.mkMerge [

        # Platform ###################################################################################################################################
        {
            nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
        }

        # HDMI Output ################################################################################################################################
        {
            boot.initrd.kernelModules = [
                "phy_rockchip_inno_hdmi" # Must load before rockchipdrm or the HDMI probe defers and the screen stays blank
                "rockchipdrm"
            ];
        }

        # Network ####################################################################################################################################
        {
            # Loaded at the very start of boot so the disks and the network are ready when the unlock needs them
            boot.initrd.kernelModules = [
                "stmmac"
                "stmmac_platform"
                "dwmac_rk"
            ];
        }

        # Storage ####################################################################################################################################
        {
            # Loaded at the very start of boot so the disks and the network are ready when the unlock needs them
            boot.initrd.kernelModules = [
                "uas"
            ];
        }

        # Backup Drive Adapter #######################################################################################################################
        {
            # Use the older, simpler USB disk protocol for these adapters, which lock up under the fast one; the f keeps a kernel default this list would otherwise drop
            boot.kernelParams = [
                "usb-storage.quirks=${lib.concatMapStringsSep "," (id: "152d:${id}:uf") dataBridges}"
            ];

            services.udev.extraRules = lib.concatMapStringsSep "\n" (id: ''
                # Give the drive three minutes to answer: it pauses for long stretches while rewriting, and a timeout would disconnect it mid-write
                ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="${id}", ATTR{device/timeout}="180"

                # Do not use the drive's timing as a source of randomness
                ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="${id}", ATTR{queue/add_random}="0"

                # Send the largest requests the adapter accepts, so big reads need fewer round trips
                ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="${id}", ATTR{device/max_sectors}="1024"
            '') dataBridges;
        }

        # Root Drive Adapter #########################################################################################################################
        {
            # Slow down the first moments of USB setup for this adapter; without it, it sometimes rejects the setup and the root drive never appears
            boot.kernelParams = [ "usbcore.quirks=152d:1561:gn" ];

            # Applied in early boot as well, because the encrypted root copies these settings from the drive at the moment it is opened
            services.udev.extraRules = rootBridgeRules;
            boot.initrd.services.udev.rules = rootBridgeRules;
        }

        # Clock ######################################################################################################################################
        {
            # Loads RTC drivers early, enables clock sync for accurate logs
            boot.initrd.kernelModules = [ "rtc_rk808" ];
        }

    ];
}
