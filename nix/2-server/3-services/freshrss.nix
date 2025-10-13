{ inputs, config, ... }:
{
    sops.secrets.freshrss_password.sopsFile = "${inputs.self}/secrets/2-server.yaml";
    sops.secrets.https_certificate = {
        sopsFile = "${inputs.self}/secrets/2-server.yaml";
        owner = "nginx";
        group = "nginx";
    };
    sops.secrets.https_certificate_key = {
        sopsFile = "${inputs.self}/secrets/2-server.yaml";
        owner = "nginx";
        group = "nginx";
    };
    services = {
        freshrss = {
            enable = true;
            baseUrl = "https://freshrss.heimdall.technet";
            dataDir = "/Storage/Services/FreshRSS/data";
            defaultUser = "beatlink";
            passwordFile = config.sops.secrets.freshrss_password.path;
        };
        nginx.virtualHosts.freshrss = {
            serverName = "freshrss.heimdall.technet";
            addSSL = true;
            sslCertificate = config.sops.secrets.https_certificate.path;
            sslCertificateKey = config.sops.secrets.https_certificate_key.path;
        };
    };
}
