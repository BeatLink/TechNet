# modules/vhost-manager.nix
{
    inputs,
    config,
    lib,
    ...
}:

let
    cfg = config.nginx-vhost;
in
{
    options.myServices = lib.mkOption {
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

    sops.secrets.https_certificate.sopsFile = "${inputs.self}/secrets/2-server.yaml";
    sops.secrets.https_certificate_key.sopsFile = "${inputs.self}/secrets/2-server.yaml";

    config = lib.mkIf (cfg != { }) {
        services.nginx.virtualHosts = lib.mapAttrs (
            name: svc:
            {
                serverName = svc.domain;
                forceSSL = true;
                sslCertificate = config.sops.secrets."https_certificate".path;
                sslCertificateKey = config.sops.secrets."https_certificate_key".path;
                locations."/" = {
                    proxyPass = "http://localhost:${toString svc.port}";
                    proxyWebsockets = true;
                };
            }
            // svc.extraConfig
        ) cfg;
    };
}
