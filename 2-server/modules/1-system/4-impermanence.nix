# Impermanent Filesystem ################################################################################################################
# 
# Heimdall follows an "Erase your Darlings" impermanent filesystem structure, powered by a LUKS encrypted BTRFS filesystem and subvolumes.
# Every boot the system performs a rollback of the BTRFS root filesystem to a clean snapshot in order to prevent the buildup of state.
#
# The majority of state including docker databases and storage drives are stored on 2 1TB Hard Drives configured for RAID 1 with a LUKS
# overlay on top. These settings decrypt that drive during boot
#
# Everything should either be generated from this repo's flake, stored in /persistent or stored on the data drives
#
# The filesystem setup was already handled by nixos-anywhere and disko during installation. These settings are merely responsible for 
# implementing the rollback and setting up persistent storage using impermanence as well as mounting the data drives
#
# See https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html 
# https://discourse.nixos.org/t/impermanence-vs-systemd-initrd-w-tpm-unlocking/25167/3
#
#######################################################################################################################################
{ config, lib, pkgs, modulesPath, ... }: {

    # Impermanent Filesystem Rollback 
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
    
    # Persistence Subvolume Mounting
    environment.persistence."/persistent" = {
        hideMounts = true;
        directories = [
            "/var/lib/nixos"
            "/var/log"            
        ];
        files = [
            { file = "/etc/machine-id"; parentDirectory = { mode = "0755"; }; }
            { file = "/etc/ssh/ssh_host_rsa_key"; parentDirectory = { mode = "0755"; }; }
        ];
    };
}