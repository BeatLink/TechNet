# Qbittorrent
#
# Qbittorrent is the torrent management server. The torrent server allows for automatic 24/7 downloading and setting of content.
#
#

{
    services.qbittorrent = {
        enable = true;
        profileDir = "/Storage/Services/Qbittorrent/profile";
        webuiPort = 9050;
        torrentingPort = 6881;
    };
    networking.firewall = {
        allowedTCPPorts = [ 6881 ];
        allowedUDPPorts = [ 6881 ];
    };
    nginx-vhosts.qbittorrent = {
        domain = "qbittorrent.heimdall.technet";
        port = 9050;
    };
}
