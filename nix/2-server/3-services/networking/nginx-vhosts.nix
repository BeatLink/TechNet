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
                    host = lib.mkOption {
                        type = lib.types.str;
                        default = "127.0.0.1";
                        description = ''
                            Address to proxy to. Defaults to loopback, for services
                            running on Heimdall itself. A TechNet address such as
                            10.100.100.2 proxies to another host over WireGuard.
                        '';
                    };
                    port = lib.mkOption {
                        type = lib.types.port;
                        description = "Port to proxy to";
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
                    proxyPass = "http://${svc.host}:${toString svc.port}";
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
