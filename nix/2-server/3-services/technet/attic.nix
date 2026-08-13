# Attic ##############################################################################################################################################
#
# Binary cache for the TechNet. A path built on one host is pushed here and substituted by the others rather than rebuilt, which matters most for the
# aarch64 hosts whose builds are otherwise measured in hours.
#
# Caches and tokens are created once by hand with `atticd-atticadm`, the same one-time-manual-step pattern as Trilium's ETAPI token.
#

{ config, ... }:
{
    # RS256 key atticd signs its JWTs with; replacing it invalidates every token already handed out.
    sops.secrets.attic_env.sopsFile = "${config.technet.secrets.path}/attic.yaml";

    services.atticd = {
        enable = true;
        environmentFile = config.sops.secrets.attic_env.path;
        settings = {
            listen = "127.0.0.1:9400";
            allowed-hosts = [ "attic.heimdall.technet" ];
            api-endpoint = "https://attic.heimdall.technet/";
            compression.type = "zstd";
            garbage-collection.interval = "12 hours";
        };
    };

    nginx-vhosts.attic = {
        domain = "attic.heimdall.technet";
        port = 9400;
        extraConfig = {
            # A NAR upload is a single unbounded PUT, so it must neither be capped nor spooled to disk before atticd sees it.
            extraConfig = ''
                client_max_body_size 0;
                proxy_request_buffering off;
            '';
        };
    };

    # atticd keeps both its SQLite database and its chunk store in the state directory, so the whole thing lives on the data pool.
    environment.persistence."/Storage/Services/Attic".directories = [ "/var/lib/atticd" ];

    # Cache contents are reproducible and large; the marker keeps borgmatic's `exclude_if_present` from pulling them into the repo.
    systemd.tmpfiles.settings."Attic" = {
        "/Storage/Services/Attic".d = {
            user = "root";
            group = "root";
            mode = "0755";
        };
        "/Storage/Services/Attic/.nobackup".f = {
            user = "root";
            group = "root";
            mode = "0644";
        };
    };
}
