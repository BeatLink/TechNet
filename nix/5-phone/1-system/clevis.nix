{ config, pkgs, ... }:
{
    technet.clevis = {
        enable = true;
        sopsFile = "${config.technet.secrets.path}/clevis.yaml";
        retryInterval = 2;

        # Nothing on this host is ZFS any more: the root drive and the SD card are both LUKS
        datasets = [ ];

        # cryptroot from disko-btrfs-luks.nix, cryptstorage from data-drive.nix
        luksDevices = [
            "cryptroot"
            "cryptstorage"
        ];
    };

    boot.initrd.clevis.package = pkgs.clevis.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
            substituteInPlace src/pins/tang/clevis-decrypt-tang \
                --replace-fail "--connect-timeout 10" "--connect-timeout 2"
        '';
    });
}
