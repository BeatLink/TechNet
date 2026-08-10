{ config, pkgs, ... }:
{
    technet.clevis = {
        enable = true;
        sopsFile = "${config.technet.secrets.path}/clevis.yaml";
        retryInterval = 2;
    };

    boot.initrd.clevis.package = pkgs.clevis.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
            substituteInPlace src/pins/tang/clevis-decrypt-tang \
                --replace-fail "--connect-timeout 10" "--connect-timeout 2"
        '';
    });
}
