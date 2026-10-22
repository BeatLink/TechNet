{ config, pkgs, ... }:
{
    # X-Monitor's `trilium` plugin reads /etapi/metrics to check the note
    # database is actually being modified, not just that the server answers.
    # Trilium has no declarative token provisioning — ETAPI tokens are
    # generated once by hand under Options > ETAPI, then stored here to
    # match, the same one-time-manual-step pattern as Traccar's x-monitor
    # account (see traccar.nix).
    sops.secrets.trilium_etapi_token = {
        sopsFile = "${config.technet.secrets.path}/trilium.yaml";
        group = "x-monitor-credentials"; # Read by whichever X-Monitor transport runs the `cat` — the agent today, x-monitor-access as fallback
        mode = "0440";
    };

    services.trilium-server = {
        enable = true;
        instanceName = "Heimdall";
        host = "127.0.0.1";
        port = 8080;
        dataDir = "/Storage/Services/Trilium/data";
        # Drop once nixpkgs' patchelf stops overlapping node's first two segments; every release after 0.15.2 does, and it segfaults in ld.so before starting.
        package = pkgs.trilium-server.overrideAttrs (previous: {
            preFixup = (previous.preFixup or "") + ''
                export PATH=${
                    pkgs.patchelf.overrideAttrs (_: rec {
                        version = "0.15.2";
                        src = pkgs.fetchurl {
                            url = "https://github.com/NixOS/patchelf/releases/download/${version}/patchelf-${version}.tar.bz2";
                            hash = "sha256-F3RfVkFZyOIo/EEtplogSLhGxLa0Igt3y/IkFuAvLXw=";
                        };
                    })
                }/bin:$PATH
            '';
        });
    };

    # Backend scripts run as the trilium user with full filesystem, network and OS access.
    systemd.services.trilium-server.environment.TRILIUM_SECURITY_BACKEND_SCRIPTING_ENABLED = "true";

    systemd.services.trilium-stale-config-ini = {
        description = "Move aside a stale Trilium config.ini";
        wantedBy = [ "trilium-server.service" ];
        before = [ "trilium-server.service" ];
        unitConfig.RequiresMountsFor = [ "/Storage/Services/Trilium" ];
        serviceConfig.Type = "oneshot";
        script = ''
            cfg=/Storage/Services/Trilium/data/config.ini
            if [ -f "$cfg" ] && [ ! -L "$cfg" ]; then
                echo "trilium: replacing stale non-symlink $cfg (was shadowing the Nix-managed config)"
                mv -f "$cfg" "$cfg.pre-nix-backup"
            fi
        '';
    };

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
