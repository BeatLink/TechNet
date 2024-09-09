# Rollback Root #######################################################################################################################
# This folder manages all settings related to impermanence. Every boot the system performs a rollback of the BTRFS root filesystem
# to a clean snapshot in order to prevent the buildup of state.
#
# Everything should either be generated from this config file, stored in /persistent or stored on the data drives
#
# The filesystem setup was already handled by nixos-anywhere during installation. These settings are merely responsible for implementing
# the rollback and setting up persistent storage using impermanence
#
# See https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html 
# https://discourse.nixos.org/t/impermanence-vs-systemd-initrd-w-tpm-unlocking/25167/3
#
#######################################################################################################################################
{ config, lib, pkgs, modulesPath, ... }: {
    boot.initrd.systemd.services.rollback = {
        description = "Rollback BTRFS root subvolume to a pristine state";
        wantedBy = [ "initrd.target" ];
        after = [ "systemd-cryptsetup@heimdall_crypt.service" ];
        before = [ "sysroot.mount" ];
        unitConfig.DefaultDependencies = "no";
        serviceConfig.Type = "oneshot";
        script = ''
            mkdir -p /mnt &&
            mount -o subvol=/ /dev/mapper/heimdall_crypt /mnt
            btrfs subvolume list -o /mnt/root | cut -f9 -d' ' | while read subvolume; do
            echo "deleting /$subvolume subvolume..."
            btrfs subvolume delete "/mnt/$subvolume"
            done &&
            echo "deleting /root subvolume..." &&
            btrfs subvolume delete /mnt/root
            echo "restoring blank /root subvolume..." &&
            btrfs subvolume snapshot /mnt/root-blank /mnt/root                        
            umount /mnt
        '';
    };
    environment.persistence."/persistent" = {
        hideMounts = true;
        directories = [
            "/var/lib/nixos"
            "/var/log"
        ];
        files = [
            "/etc/machine-id"
        ];
    };
}