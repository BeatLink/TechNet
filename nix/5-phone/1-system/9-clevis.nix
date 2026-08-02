{ config, ... }:
{
  technet.clevis = {
    enable = false;
    sopsFile = "${config.technet.secrets.path}/clevis.yaml";
    datasets = [ "root-pool-${config.networking.hostName}/root" ];
  };
}
