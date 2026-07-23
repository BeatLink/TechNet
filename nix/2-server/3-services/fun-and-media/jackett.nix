# Jackett
#
# Jackett translates queries across many torrent trackers into a single API.
# qbittorrent.nix installs a search plugin that lets qBittorrent's own
# Search tab query this directly; a *arr app (Sonarr/Radarr) would be the
# other common way to consume it, but isn't set up here.
#

{
    services.jackett = {
        enable = true;
        dataDir = "/Storage/Services/Jackett";
        port = 9117;
    };
    nginx-vhosts.jackett = {
        domain = "jackett.heimdall.technet";
        port = 9117;
    };
}
