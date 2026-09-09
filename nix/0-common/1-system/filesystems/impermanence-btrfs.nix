# Impermanence (btrfs) ###############################################################################################################################
#
# Replaces @root and @home with fresh snapshots of their blank originals in the initrd, so only persistence.nix and home.persistence entries survive
# a boot. The btrfs counterpart of the `zfs rollback` in impermanence.nix, selected by technet.storage.backend = "btrfs-luks".
#

{
    pkgs,
    config,
    lib,
    ...
}:
{
    config = lib.mkIf (config.technet.storage.backend == "btrfs-luks") {
        boot.initrd.systemd.services.rollback = {
            description = "Roll the btrfs root and home subvolumes back to a pristine state";
            wantedBy = [ "initrd.target" ];
            after = [ "systemd-cryptsetup@cryptroot.service" ]; # The mapper device has to exist before the top level can be mounted
            before = [ "sysroot.mount" ];
            path = with pkgs; [
                btrfs-progs
                util-linux
                gawk
                coreutils
            ];
            unitConfig.DefaultDependencies = "no";
            serviceConfig.Type = "oneshot";
            script = ''
                MNT=/btrfs-rollback
                mkdir -p "$MNT"
                mount -o subvol=/ /dev/mapper/cryptroot "$MNT"
                trap 'umount "$MNT" || true' EXIT

                for sv in @root @home; do
                    # Reverse lexicographic order lists a nested subvolume before its parent, which is the order delete requires
                    btrfs subvolume list -o "$MNT/$sv" | awk '{print $NF}' | sort -r | while read -r nested; do
                        btrfs subvolume delete "$MNT/$nested"
                    done
                    btrfs subvolume delete "$MNT/$sv"
                    btrfs subvolume snapshot "$MNT/$sv-blank" "$MNT/$sv"
                done

                echo "Rollback Complete"
            '';
        };
    };
}
