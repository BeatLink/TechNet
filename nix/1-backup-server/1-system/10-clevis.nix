{ config, inputs, ... }:
let
    hn = config.networking.hostName;
in
{
    technet.clevis = {
        enable = true;
        sopsFile = "${inputs.self}/secrets/1-backup-server/clevis.yaml";
        datasets = [
            "data-pool-${hn}/storage"
            "root-pool-${hn}/root"
        ];
    };
}
