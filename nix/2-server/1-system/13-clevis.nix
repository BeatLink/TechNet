{ inputs, ... }:
{
    technet.clevis = {
        enable = true;
        sopsFile = "${inputs.self}/secrets/2-server/clevis.yaml";
    };
}
