{ inputs, ... }:
{
    technet.clevis = {
        enable = true;
        sopsFile = "${inputs.self}/secrets/1-backup-server/clevis.yaml";
    };
}
