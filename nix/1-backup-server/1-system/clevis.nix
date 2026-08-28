# Clevis #############################################################################################################################################
#
# Points the shared Clevis module at this host's key material so the encrypted pools unlock from the Tang servers at boot.
#

{ config, ... }:
{
    technet.clevis = {
        enable = true;
        sopsFile = "${config.technet.secrets.path}/clevis.yaml";
    };
}
