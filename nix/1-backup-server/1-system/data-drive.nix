# Data Drive #########################################################################################################################################
#
# The 5TB backup disk: one btrfs subvolume inside a LUKS container, the USB transport quirks its bridge needs, and ownership of the borg tree.
#
# Made with the same passphrase as the root drive, so that one console entry opens both, and carries its own clevis binding in the header, written
# by rebind-clevis from that passphrase. See docs/ragnarok.md for the layout and the commands that built it.
#

{ lib, ... }:
let
    # Every JMicron bridge the data drive has been carried in; both aborted under UAS, so each one has to be named here or it comes up unquirked
    bridges = [ "0583" "0576" ];
in
{
    config = lib.mkMerge [

        # Storage Mount ##############################################################################################################################
        {
            technet.storage.zfsDataPool = false; # /Storage is this drive, not the fleet's data-pool-Ragnarok

            # By partuuid because the partlabel is not unique across the fleet and the mapper name is what everything else spells out
            boot.initrd.luks.devices.cryptstorage = {
                device = "/dev/disk/by-partuuid/b701e0a4-fa98-467d-afd6-36cbca0f0737";
                crypttabExtraOpts = [ "nofail" ]; # A backup drive that fails to appear must leave the host reachable rather than stranding the boot
            };

            fileSystems."/Storage" = {
                device = "/dev/mapper/cryptstorage";
                fsType = "btrfs";
                options = [
                    "subvol=@storage"
                    "compress=zstd"
                    "noatime"
                    "nofail"
                    "x-systemd.device-timeout=30s" # A spinning USB disk answers only after it has spun up, which the 10s a flash device gets is not enough for
                ];
                neededForBoot = true; # Must stay true: clevis unlocks the device only in the initrd, so a stage 2 mount finds no key
            };
        }

        # USB Transport ##############################################################################################################################
        {
            # f is not optional: a quirks parameter replaces the kernel's built-in entry for the device rather than adding to it, and that entry is NO_REPORT_OPCODES
            boot.kernelParams = [ "usb-storage.quirks=${lib.concatMapStringsSep "," (id: "152d:${id}:uf") bridges}" ];

            # The shingled drive blocks past the 30s default while rewriting a band, and the reset the kernel then issues is what takes the filesystem down;
            # the drive feeds no entropy worth harvesting either. usb-storage caps a command at 120KB, so a large read costs several round trips on a bridge
            # that holds a single command; 1024 sectors is the most it will carry in one.
            services.udev.extraRules = lib.concatMapStringsSep "\n" (id: ''
                ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="${id}", ATTR{device/timeout}="180"
                ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="${id}", ATTR{queue/add_random}="0"
                ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="${id}", ATTR{device/max_sectors}="1024"
            '') bridges;
        }

        # Backup Tree Ownership ######################################################################################################################
        {
            systemd.tmpfiles.settings."Backup-Drive"."/Storage/Backups" = {
                # Z repairs but never creates, so d is what puts the tree there before the repo services start
                d = {
                    user = "borg";
                    group = "borg";
                    mode = "0750";
                };
                Z = {
                    user = "borg";
                    group = "borg";
                    mode = "0750";
                };
            };
        }
    ];
}
