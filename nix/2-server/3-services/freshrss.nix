{ inputs, config, ... }:
{
    sops.secrets.freshrss_password.sopsFile = "${inputs.self}/secrets/2-server.yaml";

    services.freshrss = {
        enable = true;
        baseUrl = "https://freshrss.heimdall.technet";
        dataDir = "/Storage/Services/FreshRSS/data";
        defaultUser = "beatlink";
        passwordFile = config.sops.secrets.freshrss_password.path;
    };
}
