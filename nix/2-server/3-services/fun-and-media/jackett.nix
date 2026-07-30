# Jackett
#
# Jackett translates queries across many torrent trackers into a single API.
# qbittorrent.nix installs a search plugin that lets qBittorrent's own
# Search tab query this directly; a *arr app (Sonarr/Radarr) would be the
# other common way to consume it, but isn't set up here.
#

{ config, lib, ... }:
{
    services.jackett = {
        enable = true;
        dataDir = "/Storage/Services/Jackett";
        port = 9117;
    };

    systemd.services.jackett.serviceConfig.ExecStart = lib.mkForce (
        "${config.services.jackett.package}/bin/Jackett --NoUpdates --ListenPrivate"
        + " --Port ${toString config.services.jackett.port}"
        + " --DataFolder '${config.services.jackett.dataDir}'"
    );
    nginx-vhosts.jackett = {
        domain = "jackett.heimdall.technet";
        port = 9117;
    };
}
