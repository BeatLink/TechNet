# modules/vhost-manager.nix
{
    config,
    lib,
    ...
}:

let
    cfg = config.nginx-vhosts;
in
{
    options.nginx-vhosts = lib.mkOption {
        type = lib.types.attrsOf (
            lib.types.submodule {
                options = {
                    port = lib.mkOption {
                        type = lib.types.port;
                        description = "Local port to proxy to";
                    };
                    domain = lib.mkOption {
                        type = lib.types.str;
                        description = "Domain name for the vhost";
                    };
                    extraConfig = lib.mkOption {
                        type = lib.types.attrs;
                        default = { };
                        description = "Extra nginx virtualHost options";
                    };
                };
            }
        );
        default = { };
        description = "Managed virtual hosts";
    };

    config = lib.mkIf (cfg != { }) {
        services.nginx.virtualHosts = lib.mapAttrs (
            name: svc:
            {
                serverName = svc.domain;
                addSSL = true;
                sslCertificate = config.sops.secrets."https_certificate".path;
                sslCertificateKey = config.sops.secrets."https_certificate_key".path;
                locations."/" = {
                    proxyPass = "http://127.0.0.1:${toString svc.port}";
                    proxyWebsockets = true;
                    recommendedProxySettings = true;

                };
            }
            // svc.extraConfig
        ) cfg;

        services.pihole-ftl.settings.dns.cnameRecords = lib.mapAttrsToList (
            name: svc: "${svc.domain},heimdall.technet"
        ) cfg;

    };
}
