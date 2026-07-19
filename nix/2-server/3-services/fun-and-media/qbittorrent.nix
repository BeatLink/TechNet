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
        serverConfig.Preferences.WebUI = {
            # Let requests originating on Heimdall itself skip the WebUI login,
            # so Vigil's qbittorrent monitor can read the API over SSH from this
            # host against 127.0.0.1 without a stored credential.
            LocalHostAuth = false;

            # Required for the above to be safe, and NOT optional here.
            #
            # nginx proxies the vhost with `proxyPass http://127.0.0.1:9050`, so
            # every request forwarded from the network arrives at qBittorrent
            # with a loopback peer address. Judged on the socket alone, those are
            # indistinguishable from genuinely local ones — LocalHostAuth = false
            # would then exempt the whole network from logging in.
            #
            # Turning this on makes qBittorrent trust the X-Forwarded-For header
            # that `recommendedProxySettings` already sends, so it evaluates the
            # ORIGINAL client address instead of nginx's. Proxied requests are
            # then correctly seen as non-local and still authenticate; only
            # processes on Heimdall itself are exempt, and those can read the
            # profile's credentials off disk regardless.
            ReverseProxySupportEnabled = true;
            TrustedReverseProxiesList = "127.0.0.1";
        };
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
