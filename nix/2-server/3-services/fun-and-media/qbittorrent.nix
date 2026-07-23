# Qbittorrent
#
# Qbittorrent is the torrent management server. The torrent server allows for automatic 24/7 downloading and setting of content.
#
# The Jackett search plugin (nova3/engines/jackett.py) lets qBittorrent's
# built-in Search tab query Jackett's indexers directly. qBittorrent only
# looks for plugins under its Data special folder, which for a custom
# --profile is <profileDir>/data/nova3/engines (NOT profileDir itself, and
# NOT profileDir/qBittorrent/... like the .conf file) — see
# SearchPluginManager::pluginsLocation() in qBittorrent's source.
#

{ pkgs, config, inputs, ... }:
let
    # Pinned to a commit (rather than tracking master) so the derivation
    # stays reproducible; bump commit + hash together to update the plugin.
    jackettPlugin = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/qbittorrent/search-plugins/62f296ed47010ab0ea9dbd43257a1a20025d1d1a/nova3/engines/jackett.py";
        hash = "sha256:17gd94bcr0b3lv7lvqnq00lw659izynpdx6rc7z71y5w3xwvpv84";
    };
in
{
    sops.secrets.qbittorrent_jackett_api_key = {
        sopsFile = "${inputs.self}/secrets/2-server/qbittorrent.yaml";
        key = "jackett_api_key";
        owner = "qbittorrent";
        group = "qbittorrent";
    };

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

    systemd.tmpfiles.rules = [
        "d /Storage/Services/Qbittorrent/profile/data/nova3/engines 0750 qbittorrent qbittorrent - -"
    ];

    systemd.services.qbittorrent = {
        # nova3 search plugins are plain Python scripts; qBittorrent shells
        # out to `python3` on PATH to run them (it does not bundle one).
        path = [ pkgs.python3 ];

        serviceConfig = {
            LoadCredential = "jackett_api_key:${config.sops.secrets.qbittorrent_jackett_api_key.path}";

            # Installs the pinned Jackett plugin script and a jackett.json
            # populated from the sops-managed API key. Runs as the service's
            # own (unprivileged) user since the unit is otherwise hardened
            # with ProtectHome/ProtectSystem, so the key path resolves through
            # LoadCredential rather than being written into the Nix store.
            ExecStartPre = [
                ''
                    ${pkgs.coreutils}/bin/install -Dm644 ${jackettPlugin} \
                        /Storage/Services/Qbittorrent/profile/data/nova3/engines/jackett.py
                ''
                ''
                    ${pkgs.jq}/bin/jq -n \
                        --arg api_key "$(cat "$CREDENTIALS_DIRECTORY/jackett_api_key")" \
                        --arg url "http://127.0.0.1:9117" \
                        '{api_key: $api_key, url: $url, tracker_first: false, thread_count: 20}' \
                        > /Storage/Services/Qbittorrent/profile/data/nova3/engines/jackett.json
                ''
            ];
        };
    };
}
