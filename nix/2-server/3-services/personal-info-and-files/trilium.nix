{ pkgs, inputs, ... }:
{
    services.trilium-server = {
        enable = true;
        package = inputs.trilium.packages.${pkgs.stdenv.hostPlatform.system}.server;
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
