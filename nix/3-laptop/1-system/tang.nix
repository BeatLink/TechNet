{ config, ... }:
{
    technet.tang.server = {
        enable = true;
        sopsFile = "${config.technet.secrets.path}/tang.yaml";
    };
}
