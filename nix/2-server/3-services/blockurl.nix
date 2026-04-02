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
    nginx-vhosts.blockurl = {
        domain = "blockurl.heimdall.technet";
        port = 9001;
    };
}
