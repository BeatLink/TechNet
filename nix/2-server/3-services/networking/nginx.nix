{
    config,
    ...
}:
{
    services.nginx = {
        enable = true;
        defaultHTTPListenPort = 80;
        defaultSSLListenPort = 443;
    };

    networking.firewall = {
        allowedTCPPorts = [
            80 # Nginx Services
            443 # Nginx Services (HTTPS)
        ];
    };
    sops.secrets.https_certificate = {
        sopsFile = "${config.technet.secrets.path}/nginx.yaml";
        owner = "nginx";
        group = "nginx";
    };
    sops.secrets.https_certificate_key = {
        sopsFile = "${config.technet.secrets.path}/nginx.yaml";
        owner = "nginx";
        group = "nginx";
    };
    services.nginx.virtualHosts."_" = {
        default = true;
        addSSL = true;
        sslCertificate = config.sops.secrets."https_certificate".path;
        sslCertificateKey = config.sops.secrets."https_certificate_key".path;
        # optionally return 444 to drop unmatched connections silently
        extraConfig = "return 444;";
    };
}
