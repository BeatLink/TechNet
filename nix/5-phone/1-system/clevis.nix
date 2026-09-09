{ config, pkgs, ... }:
{
    technet.clevis = {
        enable = true;
        sopsFile = "${config.technet.secrets.path}/clevis.yaml";
        retryInterval = 2;

        # The root pool the default would name no longer exists; the SD card is the only ZFS left on this host
        datasets = [ "data-pool-Thor/storage" ];

        # Named by disko-btrfs-luks.nix, which is what puts it in boot.initrd.luks.devices
        luksDevices = [ "cryptroot" ];
    };

    boot.initrd.clevis.package = pkgs.clevis.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
            substituteInPlace src/pins/tang/clevis-decrypt-tang \
                --replace-fail "--connect-timeout 10" "--connect-timeout 2"
        '';
    });
}
