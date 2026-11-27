{
    config,
    ...
}:
{
    services.nginx = {
        enable = true;
        defaultHTTPListenPort = 80;
        defaultSSLListenPort = 443;

        # Browsers that reached a service over https keep to https for a day; kept short and without subdomains while plain http still answers.
        # Set once for the whole http block so it also reaches vhosts that NixOS modules define, such as FreshRSS and Roundcube. nginx drops every
        # inherited add_header at the first server or location that sets one of its own; such a block needs `add_header_inherit merge;` beside it.
        appendHttpConfig = ''
            add_header Strict-Transport-Security "max-age=86400" always;
        '';
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
