# Data Drive #########################################################################################################################################
#
# The 5TB backup disk: one btrfs subvolume inside a LUKS container.
#

{
    config,
    lib,
    ...
}:
let
    luksPartition = "/dev/disk/by-partuuid/b701e0a4-fa98-467d-afd6-36cbca0f0737";

    tmpfiles = "${config.systemd.package}/bin/systemd-tmpfiles";

    # The units that write under /Storage, which storage-directories runs ahead of
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

        # Mount ######################################################################################################################################
        {
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
