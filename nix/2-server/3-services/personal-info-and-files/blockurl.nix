# https://github.com/BeatLink/BlockURL

{ config, ... }: {
    sops.secrets.blockurl_api_key = {
        owner = "blockurl";                                             # must match services.blockurl.user, which reads the key as its owner
        group = "vigil-monitor";                                        # Read by the `cut` the blockurl plugin runs on the Vigil host as the `vigil` user
        mode = "0440";
        sopsFile = "${config.technet.secrets.path}/blockurl.yaml";
    };

    services.blockurl = {
        enable = true;
        apiKeyFile = config.sops.secrets.blockurl_api_key.path;
        openFirewall = true;
        port = 9001;
        host = "127.0.0.1";
        dataDir = "/Storage/Services/BlockURL/database";
        databaseFile = "blockurl.db";
    };

    systemd.tmpfiles.settings."BlockURL"."/Storage/Services/BlockURL" = {
        d = {
            user = "blockurl";
            group = "blockurl";
            mode = "0750";
        };
        Z = {
            user = "blockurl";
            group = "blockurl";
            mode = "0750";
        };
    };

    nginx-vhosts.blockurl = {
        domain = "blockurl.heimdall.technet";
        port = 9001;
    };
}
