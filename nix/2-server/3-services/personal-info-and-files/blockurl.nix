# https://hub.docker.com/repository/docker/beatlink/blockurl
# https://github.com/BeatLink/BlockURL

{
    services.blockurl = {
        enable = true;
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
