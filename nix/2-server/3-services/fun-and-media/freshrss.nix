{
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
        sopsFile = "${config.technet.secrets.path}/freshrss.yaml";
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
        sopsFile = "${config.technet.secrets.path}/freshrss.yaml";
        group = "vigil-monitor";                                        # Read by whichever Vigil transport runs the `cat` — the agent today, vigil-access as fallback
        mode = "0440";
    };

    systemd.tmpfiles.settings."FreshRSS"."/Storage/Services/FreshRSS" = {
        d = {
            user = "freshrss";
            group = "freshrss";
            mode = "0750";
        };
        Z = {
            user = "freshrss";
            group = "freshrss";
            mode = "0750";
        };
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
