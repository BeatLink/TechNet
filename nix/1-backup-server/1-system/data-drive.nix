# Data Drive #########################################################################################################################################
#
# The 5TB backup disk: one btrfs subvolume inside a LUKS container.
#

{ lib, pkgs, ... }:
let
    luksPartition = "/dev/disk/by-partuuid/b701e0a4-fa98-467d-afd6-36cbca0f0737";
in
{
    config = lib.mkMerge [

        # Storage Mount ##############################################################################################################################
        {
            technet.storage.zfsDataPool = false; # /Storage is this drive, not the fleet's data-pool-Ragnarok

            boot.initrd.luks.devices.cryptstorage = {
                device = luksPartition;
                crypttabExtraOpts = [ "nofail" ];
            };
        }

        # Missed Unlock ##############################################################################################################################
        {
            # The drive's adapter sometimes rejects its first USB setup and the initrd moves on without it (both mount and unlock are nofail), so once
            # the network is up: re-probe any adapter left unconfigured, unlock the container against tang, and mount.
            systemd.services.storage-recover = {
                description = "Mount /Storage if the initrd missed the backup drive";
                wantedBy = [ "multi-user.target" ];
                after = [ "network-online.target" ];
                wants = [ "network-online.target" ];
                unitConfig.ConditionPathIsMountPoint = "!/Storage";
                serviceConfig.Type = "oneshot";
                path = [
                    pkgs.clevis
                    pkgs.coreutils
                ];
                script = ''
                    for dev in /sys/bus/usb/devices/*; do
                        [ -r "$dev/idVendor" ] && [ "$(cat "$dev/idVendor")" = 152d ] || continue
                        [ -z "$(cat "$dev/bConfigurationValue")" ] || continue
                        name=$(basename "$dev")
                        echo "storage-recover: re-probing unconfigured adapter $name"
                        echo "$name" > /sys/bus/usb/drivers/usb/unbind
                        sleep 2
                        echo "$name" > /sys/bus/usb/drivers/usb/bind
                    done

                    for _ in $(seq 1 30); do
                        [ -e ${luksPartition} ] && break
                        sleep 2
                    done
                    [ -e ${luksPartition} ] || { echo "storage-recover: backup drive still absent"; exit 0; }

                    [ -e /dev/mapper/cryptstorage ] || clevis luks unlock -d ${luksPartition} -n cryptstorage
                    systemctl start Storage.mount
                '';
            };

            fileSystems."/Storage" = {
                device = "/dev/mapper/cryptstorage";
                fsType = "btrfs";
                options = [
                    "subvol=@storage"
                    "compress=zstd"
                    "noatime"
                    "nofail"
                    "x-systemd.device-timeout=90s" # Waits on the clevis unlock, not the disk, and that takes ~35s here
                ];
                neededForBoot = true;
            };
        }

        # Scrub State ################################################################################################################################
        {
            environment.persistence."/persistent".directories = [ "/var/lib/btrfs" ];
        }
    ];
}
