{ config, ... }:
{
    # Vigil's `trilium` plugin reads /etapi/metrics to check the note
    # database is actually being modified, not just that the server answers.
    # Trilium has no declarative token provisioning — ETAPI tokens are
    # generated once by hand under Options > ETAPI, then stored here to
    # match, the same one-time-manual-step pattern as Traccar's vigil
    # account (see traccar.nix).
    sops.secrets.trilium_etapi_token = {
        sopsFile = "${config.technet.secrets.path}/trilium.yaml";
        owner = "vigil-access";
    };

    services.trilium-server = {
        enable = true;
        instanceName = "Heimdall";
        host = "127.0.0.1";
        port = 8080;
        dataDir = "/Storage/Services/Trilium/data";
    };

    system.activationScripts.triliumStaleConfigIni = ''
        cfg=/Storage/Services/Trilium/data/config.ini
        if [ -f "$cfg" ] && [ ! -L "$cfg" ]; then
            echo "trilium: replacing stale non-symlink $cfg (was shadowing the Nix-managed config)"
            mv -f "$cfg" "$cfg.pre-nix-backup"
        fi
    '';

    nginx-vhosts.trilium = {
        domain = "trilium.heimdall.technet";
        port = 8080;
    };

    systemd.tmpfiles.settings."Trilium"."/Storage/Services/Trilium".Z = {
        user = "trilium";
        group = "trilium";
        mode = "0750";
    };
}
