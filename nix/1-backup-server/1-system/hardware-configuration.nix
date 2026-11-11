# Hardware Configuration #############################################################################################################################
#
# The Rock64 board, the drivers it needs before the disks can be unlocked, and the fixes its USB 3 controller and three USB-to-SATA adapters need
# to work reliably.
#

{ lib, pkgs, ... }:
let
    # The adapter the backup drive is plugged in through
    dataBridge = "0576";

    # The adapter the root drive is plugged in through
    rootBridge = "0583";

    # The adapter the root drive used to sit in, kept as a spare
    spareBridge = "1561";

    # One setting for every adapter, because a second usb-storage.quirks on the command line replaces the first instead of adding to it
    storageQuirks = "152d:${dataBridge}:u,152d:${rootBridge}:f,152d:${spareBridge}:u";

    # The most the root drive is asked to erase in one request: a SATA erase range holds at most 65535 sectors, and the kernel wants a multiple of 4 KiB
    maxDiscardBytes = toString (8191 * 4096);

    rootBridgeRules = ''
        # Treat the root drive as the SSD it is, and do not use its timing as a source of randomness
        ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="${rootBridge}", ATTR{queue/rotational}="0", ATTR{queue/add_random}="0"

        # Let the SSD erase unused space, then cap the request size; the cap must come second, and tee is spelled out because early boot has no PATH
        ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="${rootBridge}", RUN+="/bin/sh -c 'echo unmap | ${pkgs.coreutils}/bin/tee /sys%p/device/scsi_disk/*/provisioning_mode >/dev/null && echo ${maxDiscardBytes} > /sys%p/queue/discard_max_bytes'"
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
                "usb_storage"
            ];
        }

        # USB 3 Controller ###########################################################################################################################
        {
            # Stop the controller parking on one SuperSpeed bulk pipe: with both drives behind the hub under load, the controller stops answering and
            # the kernel declares it dead, dropping every disk at once. Mainline carries the fix but leaves it to each board's device tree.
            hardware.deviceTree = {
                # Without the name, systemd-boot leaves the firmware's device tree in place and the overlay never reaches the kernel
                name = "rockchip/rk3328-rock64.dtb";
                overlays = [
                    {
                        name = "usb3-no-park-mode";
                        dtsText = ''
                            /dts-v1/;
                            /plugin/;
                            / {
                                compatible = "pine64,rock64", "rockchip,rk3328";
                                fragment@0 {
                                    target-path = "/usb@ff600000";
                                    __overlay__ {
                                        snps,parkmode-disable-ss-quirk;
                                    };
                                };
                            };
                        '';
                    }
                ];
            };
        }

        # Disk Protocol ##############################################################################################################################
        {
            boot.kernelParams = [
                # Use the older, simpler USB disk protocol for the backup drive's adapter, which locks up under the fast one, and for the spare, which
                # times out on commands there. The root drive's runs the fast one, where the f keeps a kernel default this list would otherwise drop.
                "usb-storage.quirks=${storageQuirks}"

                # Slow down the first moments of USB setup for these adapters; without it they sometimes reject the setup and the drive never appears.
                # One setting for both, because a second usbcore.quirks on the command line replaces the first.
                "usbcore.quirks=152d:1561:gn,152d:0576:gn"
            ];
        }

        # Backup Drive Adapter #######################################################################################################################
        {
            services.udev.extraRules = ''
                # Give the drive three minutes to answer: it pauses for long stretches while rewriting, and a timeout would disconnect it mid-write
                ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="${dataBridge}", ATTR{device/timeout}="180"

                # Do not use the drive's timing as a source of randomness
                ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="${dataBridge}", ATTR{queue/add_random}="0"

                # Keep each request to 32 KiB: with larger ones the adapter's bulk reads fail every so often behind the hub and the kernel resets it
                ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="${dataBridge}", ATTR{device/max_sectors}="64"
            '';
        }

        # Root Drive Adapter #########################################################################################################################
        {
            # Applied in early boot as well, because the encrypted root copies these settings from the drive at the moment it is opened
            services.udev.extraRules = rootBridgeRules;
            boot.initrd.services.udev.rules = rootBridgeRules;
        }

        # Clock ######################################################################################################################################
        {
            # This RTC has no battery, so after a power cut it reads 2016 and RTC_HCTOSYS sets the clock backwards to it, which journald answers by
            # rotating the log it is writing. Keeping the driver out means nothing reads it; timesyncd's persisted clock file is the floor instead.
            boot.blacklistedKernelModules = [ "rtc_rk808" ];
        }

    ];
}
