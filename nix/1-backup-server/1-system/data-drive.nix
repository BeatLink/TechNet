# Data Drive #########################################################################################################################################
#
# The 5TB backup disk: one btrfs subvolume inside a LUKS container.
#

{
    config,
    lib,
    pkgs,
    ...
}:
let
    luksPartition = "/dev/disk/by-partuuid/b701e0a4-fa98-467d-afd6-36cbca0f0737";

    tmpfiles = "${config.systemd.package}/bin/systemd-tmpfiles";

    # The units storage-recover starts once it has mounted the drive late, since a unit that failed on the missing mount is not retried by itself
    dependents = [
        "syncthing.service"
        "ir-blaster.service"
    ]
    ++ map (name: "borgbackup-repo-${name}.service") (
        builtins.attrNames config.services.borgbackup.repos
    );
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
                    pkgs.curl # clevis reaches tang through it
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
                    systemctl start --no-block storage-directories.service ${lib.concatStringsSep " " dependents}
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

        # Storage Dependents #########################################################################################################################
        # Everything that writes under /Storage is bound to the mount, so with the drive missing each of them fails rather than writing into the empty
        # mountpoint on the root SSD: Syncthing there builds a fresh config and syncs every folder onto it.
        {
            systemd.services =
                lib.genAttrs
                    (
                        [
                            "storage-directories"
                            "syncthing"
                            "syncthing-init"
                        ]
                        ++ map (name: "borgbackup-repo-${name}") (builtins.attrNames config.services.borgbackup.repos)
                    )
                    (_: {
                        unitConfig.RequiresMountsFor = [ "/Storage" ];
                    });
        }

        # Folder Structure ###########################################################################################################################
        # The tmpfiles rules under /Storage are taken out of the boot-time and switch-time runs and applied by their own unit, which needs the mount.
        {
            systemd.services = {
                systemd-tmpfiles-setup.serviceConfig.ExecStart = [
                    ""
                    "${tmpfiles} --create --remove --boot --exclude-prefix=/dev --exclude-prefix=/Storage"
                ];
                systemd-tmpfiles-resetup.serviceConfig.ExecStart = [
                    ""
                    "${tmpfiles} --create --remove --exclude-prefix=/dev --exclude-prefix=/Storage"
                ];

                storage-directories = {
                    description = "Create the folder structure under /Storage";
                    wantedBy = [ "multi-user.target" ];
                    before = dependents;
                    serviceConfig = {
                        Type = "oneshot";
                        ExecStart = "${tmpfiles} --create --prefix=/Storage";
                    };
                };
            };
        }

        # Scrub State ################################################################################################################################
        {
            environment.persistence."/persistent".directories = [ "/var/lib/btrfs" ];
        }
    ];
}
