{
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
}
