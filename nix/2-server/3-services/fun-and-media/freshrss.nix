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
