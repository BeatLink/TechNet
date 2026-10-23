# https://github.com/BeatLink/BlockURL

{ config, ... }: {
    # X-Monitor's own client key; the server itself holds only the hashes below.
    sops.secrets.blockurl_x_monitor_api_key = {
        group = "x-monitor-credentials"; # Read by the `cat` the blockurl plugin runs on the X-Monitor host as the `x-monitor` user
        mode = "0440";
        sopsFile = "${config.technet.secrets.path}/blockurl.yaml";
    };

    sops.secrets.blockurl_storage_secret.sopsFile = "${config.technet.secrets.path}/blockurl.yaml";

    services.blockurl = {
        enable = true;
        storageSecretFile = config.sops.secrets.blockurl_storage_secret.path;

        # One key per client, made with `openssl rand -hex 32` and hashed with `printf %s KEY | sha256sum`; the keys sit in each host's blockurl.yaml.
        apiKeyHashes = {
            heimdall-vigil = "b3323825f9d79d3b3c043238ceea48239851ddde5ad447cb2d828af4ba0811fe";
            odin-gallery-dl = "9bcc27946a6570367a65ee99af097a22eddd9a87956fb30c0fb7006703f5ce13";
            firefox = "15db9d90b5832f1d715c314700af94ed12055b574d90cf684d24ee9a8aa863e5"; # One key for every Firefox, since the add-on keeps it in synced storage
        };
        openFirewall = true;
        port = 9001;
        host = "127.0.0.1";
        dataDir = "/Storage/Services/BlockURL/database";
        databaseFile = "blockurl.db";
    };

    # Its own hand-made dataset with sync=disabled, because every block is a SQLite commit and SMR syncs hold it past the busy timeout.
    fileSystems."/Storage/Services/BlockURL" = {
        device = "data-pool-Heimdall/storage/blockurl";
        fsType = "zfs";
        options = [
            "zfsutil"
            "nofail"
        ];
        neededForBoot = true;
    };
    systemd.services.blockurl.unitConfig.RequiresMountsFor = [ "/Storage/Services/BlockURL" ];

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
