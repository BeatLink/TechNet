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

        # Matches the Downloading/Seeding split that already exists under
        # Torrents/: in-progress torrents go to Downloading, and qBittorrent
        # moves them to Seeding on completion. Keeping partials out of the
        # completed directory matters here because Downloads is a sendreceive
        # Syncthing folder -- otherwise every partial file syncs out and then
        # re-syncs repeatedly as it grows.
        #
        # The config previously held the upstream container defaults
        # (/downloads/, /downloads/incomplete/), which are not paths on this
        # host; downloads were landing in the Downloads root instead. Both key
        # pairs are set because qBittorrent migrated Downloads\* to Session\*
        # and reads whichever its config version calls for.
        serverConfig.BitTorrent.Session = {
            DefaultSavePath = "/Storage/Files/Downloads/Torrents/Seeding";
            TempPath = "/Storage/Files/Downloads/Torrents/Downloading";
            TempPathEnabled = true;
        };
        serverConfig.Preferences.Downloads = {
            SavePath = "/Storage/Files/Downloads/Torrents/Seeding";
            TempPath = "/Storage/Files/Downloads/Torrents/Downloading";
            TempPathEnabled = true;
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

    # Lets Syncthing (which runs as beatlink) delete and re-version completed
    # downloads, rather than only read them. Paired with UMask=0002 below:
    # without the group membership the group-write bit would go unused, and
    # without the umask the membership would not help on new files.
    users.users.beatlink.extraGroups = [ "qbittorrent" ];

    # Downloads completed before UMask=0002 are still mode 0755 and stay
    # undeletable by Syncthing. Targeted at qbittorrent-owned paths only: a
    # blanket rule over /Storage/Files/Downloads would rewrite metadata on all
    # ~42k entries there, almost all of which are beatlink's and already fine.
    # `X` (capital) adds +x to directories for traversal without making files
    # executable.
    system.activationScripts.qbittorrentDownloadsGroupWrite = ''
        if [ -d /Storage/Files/Downloads ]; then
            ${pkgs.findutils}/bin/find /Storage/Files/Downloads -user qbittorrent \
                -exec ${pkgs.coreutils}/bin/chmod g+rwX {} + 2>/dev/null || true
        fi
    '';

    systemd.tmpfiles.rules = [
        # Save and temp paths, group-writable with setgid so Syncthing (via the
        # qbittorrent group) can delete what lands here and new subdirectories
        # inherit the group. These already existed as qbittorrent:rtkit 0755,
        # which left Syncthing unable to remove completed downloads.
        "d /Storage/Files/Downloads/Torrents/Seeding 2775 qbittorrent qbittorrent - -"
        "d /Storage/Files/Downloads/Torrents/Downloading 2775 qbittorrent qbittorrent - -"

        # qBittorrent itself creates data/ and data/nova3/ (root-owned, via
        # tmpfiles running before this unit's first start) before our
        # ExecStartPre ever runs, so every level needs an explicit rule —
        # a rule for just the engines/ leaf leaves its unwritable parents.
        "Z /Storage/Services/Qbittorrent/profile/data 0750 qbittorrent qbittorrent - -"
        "Z /Storage/Services/Qbittorrent/profile/data/nova3 0750 qbittorrent qbittorrent - -"
        "d /Storage/Services/Qbittorrent/profile/data/nova3/engines 0750 qbittorrent qbittorrent - -"
    ];

    systemd.services.qbittorrent = {
        # nova3 search plugins are plain Python scripts; qBittorrent shells
        # out to `python3` on PATH to run them (it does not bundle one).
        path = [ pkgs.python3 ];

        serviceConfig = {
            # Completed downloads land in /Storage/Files/Downloads, which is a
            # sendreceive Syncthing folder scanned as beatlink. The default 0022
            # umask makes them qbittorrent:qbittorrent 0755 -- readable, but not
            # writable by the group, so Syncthing could not remove a file when a
            # peer deleted it ("trashcan versioner: archive: remove ...:
            # permission denied") and the delete never propagated.
            #
            # 0002 keeps group write on new downloads; beatlink is added to the
            # qbittorrent group below so Syncthing can act on them.
            UMask = "0002";

            LoadCredential = "jackett_api_key:${config.sops.secrets.qbittorrent_jackett_api_key.path}";

            # Installs the pinned Jackett plugin script and a jackett.json
            # populated from the sops-managed API key. Runs as the service's
            # own (unprivileged) user since the unit is otherwise hardened
            # with ProtectHome/ProtectSystem, so the key path resolves through
            # LoadCredential rather than being written into the Nix store.
            #
            # ExecStartPre lines are argv-split by systemd, not run through a
            # shell, so $(), quoting, and > redirection need an explicit `sh
            # -c` wrapper (writeShellScript) rather than a bare command string.
            ExecStartPre = [
                (pkgs.lib.getExe (pkgs.writeShellApplication {
                    name = "qbittorrent-install-jackett-plugin";
                    runtimeInputs = [ pkgs.coreutils ];
                    text = ''
                        install -Dm644 ${jackettPlugin} \
                            /Storage/Services/Qbittorrent/profile/data/nova3/engines/jackett.py
                    '';
                }))
                (pkgs.lib.getExe (pkgs.writeShellApplication {
                    name = "qbittorrent-render-jackett-config";
                    runtimeInputs = [ pkgs.jq ];
                    text = ''
                        jq -n \
                            --arg api_key "$(cat "$CREDENTIALS_DIRECTORY/jackett_api_key")" \
                            --arg url "http://127.0.0.1:9117" \
                            '{api_key: $api_key, url: $url, tracker_first: false, thread_count: 20}' \
                            > /Storage/Services/Qbittorrent/profile/data/nova3/engines/jackett.json
                    '';
                }))
            ];
        };
    };
}
