{ inputs, pkgs, ... }:
let
    trilium = inputs.trilium-notes.packages.${pkgs.stdenv.hostPlatform.system}.server;
in
{
    services.trilium-server = {
        enable = true;
        instanceName = "Heimdall";
        port = 8080;
        dataDir = "/Storage/Services/Trilium/data";
        package = trilium;
    };

    nginx-vhosts.trilium = {
        domain = "trilium.heimdall.technet";
        port = 8080;
    };
}
