{ inputs, ... }:
{
    # Vigil's `trilium` plugin reads /etapi/metrics to check the note
    # database is actually being modified, not just that the server answers.
    # Trilium has no declarative token provisioning — ETAPI tokens are
    # generated once by hand under Options > ETAPI, then stored here to
    # match, the same one-time-manual-step pattern as Traccar's vigil
    # account (see traccar.nix).
    sops.secrets.trilium_etapi_token = {
        sopsFile = "${inputs.self}/secrets/2-server/trilium.yaml";
        owner = "vigil-access";
    };

    services.trilium-server = {
        enable = true;
        instanceName = "Heimdall";
        port = 8080;
        dataDir = "/Storage/Services/Trilium/data";
    };

    nginx-vhosts.trilium = {
        domain = "trilium.heimdall.technet";
        port = 8080;
    };

    systemd.tmpfiles.rules = [
        "Z /Storage/Services/Trilium 0750 trilium trilium - -"
    ];
}
