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
        sopsFile = "${config.technet.secrets.path}/qbittorrent.yaml";
        key = "jackett_api_key";
        owner = "beatlink";
        group = "beatlink";
    };

    # The WebUI password, as qBittorrent's own PBKDF2-HMAC-SHA512 digest
    # (@ByteArray(<b64 salt>:<b64 key>), 100k iterations) rather than plaintext.
    # It cannot go in serverConfig: the module renders that with
    # pkgs.writeText, so anything there is world-readable in the Nix store.
    sops.secrets.qbittorrent_webui_password_hash = {
        sopsFile = "${config.technet.secrets.path}/qbittorrent.yaml";
        key = "webui_password_hash";
        owner = "beatlink";
        group = "beatlink";
    };

    services.qbittorrent = {
        enable = true;
        # Runs as beatlink so completed downloads land already owned by the
        # account Syncthing runs as. Syncthing syncs permission bits on the
        # Downloads folder (ignorePerms = false), and chmod is owner-restricted,
        # so a separate qbittorrent account would stall that folder no matter
        # what group memberships were arranged.
        user = "beatlink";
        group = "beatlink";
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

    # Downloads and profile state created while qbittorrent ran under its own
    # account are still owned by a uid that no longer has a name, which leaves
    # Syncthing unable to chmod them now that it syncs permission bits. Targeted
    # at those paths only: a blanket chown over /Storage/Files/Downloads would
    # rewrite metadata on all ~42k entries there, almost all of which are
    # beatlink's already.
    system.activationScripts.qbittorrentChownToBeatlink = ''
        for dir in /Storage/Files/Downloads /Storage/Services/Qbittorrent; do
            if [ -d "$dir" ]; then
                ${pkgs.findutils}/bin/find "$dir" \! -user beatlink \
                    -exec ${pkgs.coreutils}/bin/chown beatlink:beatlink {} + 2>/dev/null || true
            fi
        done
    '';

    systemd.tmpfiles.settings."Qbittorrent" = {
        # setgid keeps the group on anything created below these, matching both the service and Syncthing
        "/Storage/Files/Downloads/Torrents/Seeding".d = {
            user = "beatlink";
            group = "beatlink";
            mode = "2775";
        };
        "/Storage/Files/Downloads/Torrents/Downloading".d = {
            user = "beatlink";
            group = "beatlink";
            mode = "2775";
        };

        # Every level needs its own entry; qBittorrent creates these root-owned before ExecStartPre runs
        "/Storage/Services/Qbittorrent/profile/data".Z = {
            user = "beatlink";
            group = "beatlink";
            mode = "0750";
        };
        "/Storage/Services/Qbittorrent/profile/data/nova3".Z = {
            user = "beatlink";
            group = "beatlink";
            mode = "0750";
        };
        "/Storage/Services/Qbittorrent/profile/data/nova3/engines".d = {
            user = "beatlink";
            group = "beatlink";
            mode = "0750";
        };
    };

    systemd.services.qbittorrent = {
        # nova3 search plugins are plain Python scripts; qBittorrent shells
        # out to `python3` on PATH to run them (it does not bundle one).
        path = [ pkgs.python3 ];

        serviceConfig = {
            # Completed downloads land in /Storage/Files/Downloads, a
            # sendreceive Syncthing folder that now syncs permission bits.
            # Keeping group write on new downloads means the modes qbittorrent
            # creates already match what the setgid directories above imply, so
            # Syncthing propagates them out rather than immediately chmod-ing
            # every finished file to add the bit.
            UMask = "0002";

            LoadCredential = [
                "jackett_api_key:${config.sops.secrets.qbittorrent_jackett_api_key.path}"
                "webui_password_hash:${config.sops.secrets.qbittorrent_webui_password_hash.path}"
            ];

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
                # Runs after the module's own ExecStartPre, which reinstalls
                # qBittorrent.conf from the store on every start -- so without
                # this the password key would be wiped each restart and
                # qBittorrent would print a new temporary password to the
                # journal. Appends the key if absent, replaces it if present.
                (pkgs.lib.getExe (pkgs.writeShellApplication {
                    name = "qbittorrent-set-webui-password";
                    runtimeInputs = [ pkgs.gawk pkgs.coreutils ];
                    text = ''
                        conf=/Storage/Services/Qbittorrent/profile/qBittorrent/config/qBittorrent.conf
                        hash=$(cat "$CREDENTIALS_DIRECTORY/webui_password_hash")

                        # Inserted directly under [Preferences] rather than
                        # appended, so it lands in the right section even if a
                        # later-sorting one is ever added to serverConfig. awk
                        # rather than sed because the base64 hash contains / and
                        # & , which sed's s/// would interpret.
                        awk -v hash="$hash" '
                            /^WebUI\\Password_PBKDF2=/ { next }
                            { print }
                            /^\[Preferences\]$/ { print "WebUI\\Password_PBKDF2=" hash }
                        ' "$conf" > "$conf.new"
                        mv -f "$conf.new" "$conf"
                        chmod 600 "$conf"
                    '';
                }))
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
