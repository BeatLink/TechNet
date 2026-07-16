# https://github.com/BeatLink/BlockURL

{ inputs, config, ... }: {
    sops.secrets.blockurl_api_key = {
        owner = "blockurl"; # must match services.blockurl.user
        sopsFile = "${inputs.self}/secrets/2-server/blockurl.yaml";
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

    systemd.tmpfiles.rules = [
        "d /Storage/Services/BlockURL 0750 blockurl blockurl - -"
        "Z /Storage/Services/BlockURL 0750 blockurl blockurl - -"
    ];

    nginx-vhosts.blockurl = {
        domain = "blockurl.heimdall.technet";
        port = 9001;
    };
}
