{
    inputs,
    config,
    ...
}:
{
    # README: Feed updates will fail if IPV6 is disabled on the host system. This can be solved by setting the following
    #   ./data/config.php
    #         'curl_options' => array (
    #               CURLOPT_DNS_SERVERS => '8.8.8.8,1.1.1.1',
    #               CURLOPT_IPRESOLVE => CURL_IPRESOLVE_V4,
    #           ),

    sops.secrets.freshrss_password = {
        sopsFile = "${inputs.self}/secrets/2-server/freshrss.yaml";
        owner = "freshrss";
        group = "freshrss";
    };

    # Vigil's `freshrss` plugin authenticates to the Fever API as this same
    # (beatlink) user to check feed-refresh staleness. FreshRSS has no
    # separate declarative API-password option — it must be set once by hand
    # under Settings > Authentication > "API management" for this user, then
    # stored here to match, the same one-time-manual-step pattern as
    # Traccar's vigil account (see traccar.nix).
    sops.secrets.freshrss_api_password = {
        sopsFile = "${inputs.self}/secrets/2-server/freshrss.yaml";
        owner = "vigil-access";
    };

    systemd.tmpfiles.rules = [
        "d /Storage/Services/FreshRSS 0750 freshrss freshrss - -"
        "Z /Storage/Services/FreshRSS 0750 freshrss freshrss - -"
    ];

    services = {
        freshrss = {
            enable = true;
            baseUrl = "https://freshrss.heimdall.technet";
            dataDir = "/Storage/Services/FreshRSS/data";
            defaultUser = "beatlink";
            passwordFile = config.sops.secrets.freshrss_password.path;
            api.enable = true;
        };

        pihole-ftl.settings.dns.cnameRecords = [ "freshrss.heimdall.technet,heimdall.technet" ];

        nginx.virtualHosts.freshrss = {
            serverName = "freshrss.heimdall.technet";
            addSSL = true;
            sslCertificate = config.sops.secrets."https_certificate".path;
            sslCertificateKey = config.sops.secrets."https_certificate_key".path;
        };
    };
}
