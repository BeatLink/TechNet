# Impermanent Filesystem ################################################################################################################
# 
# Odin follows an "Erase your Darlings" impermanent filesystem structure, powered by an encrypted ZFS filesystem and subvolumes.
# Every boot the system performs a rollback of the ZFS root filesystem to a clean snapshot in order to prevent the buildup of state.
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
        description = "Rollback ZFS root subvolume to a pristine state";
        wantedBy = [ "initrd.target" ];
        after = ["zfs-import-zfspool.service"];
        before = [ "sysroot.mount" ];
        path = with pkgs; [ zfs ];
        unitConfig.DefaultDependencies = "no";
        serviceConfig.Type = "oneshot";
        script = ''
            zfs rollback -r  zfspool/root@blank && 
            zfs rollback -r  zfspool/home@blank && 
            echo "Rollback Complete"
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
        ];
    };
}