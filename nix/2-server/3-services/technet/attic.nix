# Attic ##############################################################################################################################################
#
# Binary cache for the TechNet. A path built on one host is pushed here and substituted by the others rather than rebuilt, which matters most for the
# aarch64 hosts whose builds are otherwise measured in hours.
#
# Caches and tokens are created once by hand with `atticd-atticadm`, the same one-time-manual-step pattern as Trilium's ETAPI token.
#

{ config, pkgs, ... }:
{
    # RS256 key atticd signs its JWTs with; replacing it invalidates every token already handed out.
    sops.secrets.attic_env.sopsFile = "${config.technet.secrets.path}/attic.yaml";

    # The module installs only the atticadm wrapper; creating caches and reading keys is the client's job.
    environment.systemPackages = [ pkgs.attic-client ];

    # Heimdall pushes too, so the nightly preseed build in cache-preseed.nix lands in the cache rather than only in Heimdall's own store.
    technet.atticPush.enable = true;

    services.atticd = {
        enable = true;
        environmentFile = config.sops.secrets.attic_env.path;
        settings = {
            listen = "127.0.0.1:9400";
            allowed-hosts = [ "attic.heimdall.technet" ];
            api-endpoint = "https://attic.heimdall.technet/";
            compression.type = "zstd";
            garbage-collection = {
                interval = "12 hours";

                # Without this the collector runs and deletes nothing, because the default is to keep every path forever. What the fleet actually
                # substitutes is the last couple of nixpkgs bumps, and the pool this sits on has no redundancy left to spare.
                default-retention-period = "30 days";
            };
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
    #
    # The private path, not /var/lib/atticd: the service runs DynamicUser, so systemd owns /var/lib/private/atticd and leaves the shorter path as a
    # symlink to it. Binding over /var/lib/atticd instead makes systemd try to migrate a mountpoint and fail the unit with EBUSY.
    environment.persistence."/Storage/Services/Attic".directories = [ "/var/lib/private/atticd" ];

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
