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
}
