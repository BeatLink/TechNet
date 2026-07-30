{ config, ... }:
{
    technet.clevis = {
        enable = true;
        sopsFile = "${config.technet.secrets.path}/clevis.yaml";
    };
}
