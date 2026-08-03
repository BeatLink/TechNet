{ config, ... }:
{
  technet.clevis = {
    enable = true;
    sopsFile = "${config.technet.secrets.path}/clevis.yaml";
    datasets = [ "root-pool-${config.networking.hostName}/root" ];
  };
}
