# Stremio ############################################################################################################################################
#
# A shared Stremio for the network: the streaming server that turns a torrent into a playable HTTP stream, and the web UI that drives it.
# Between them they stand in for the desktop app -- any browser on TechNet opens the UI and plays through Heimdall.
#

{
    lib,
    pkgs,
    ...
}:
let
    webDomain = "stremio.heimdall.technet";
    serverDomain = "stremio-server.heimdall.technet";

    # server.js hardcodes this and steps up to 11474 if it is taken; PORT is read only by the addon SDK and does not move this listener.
    serverPort = 11470;

    # nixpkgs already fetches the unfree server.js blob for stremio-service, so taking it from there keeps this on the version it tested.
    server = pkgs.stremio-service.server;

    # The build above registers no service worker, but a browser that loaded an earlier build still has the old one, which precaches
    # index.html and answers a bare "/" from cache without ever asking nginx. Serving this in its place retires those registrations:
    # the browser re-fetches the worker on navigation, and this one unregisters itself and empties the caches. It has no fetch handler,
    # so it never serves anything in the meantime.
    serviceWorkerKillSwitch = pkgs.writeText "stremio-web-service-worker.js" ''
        self.addEventListener("install", function () {
            self.skipWaiting();
        });

        self.addEventListener("activate", function (event) {
            event.waitUntil(
                (async function () {
                    await self.registration.unregister();
                    for (const key of await caches.keys()) {
                        await caches.delete(key);
                    }
                })()
            );
        });
    '';

    # Built from source rather than taken from upstream's release zip, so the streaming server it defaults to is set here instead of
    # being whatever address the published bundle was compiled with.
    web = pkgs.callPackage ./stremio-web.nix {
        defaultStreamingServer = "https://${serverDomain}/";
    };

in
{
    config = lib.mkMerge [

        # Streaming Server ###########################################################################################################################
        {
            systemd.services.stremio-server = {
                description = "Stremio streaming server";
                wantedBy = [ "multi-user.target" ];
                wants = [ "network-online.target" ];
                after = [ "network-online.target" ];

                environment = {
                    APP_PATH = "/var/lib/stremio-server";
                    FFMPEG_BIN = lib.getExe' pkgs.jellyfin-ffmpeg "ffmpeg";
                    FFPROBE_BIN = lib.getExe' pkgs.jellyfin-ffmpeg "ffprobe";
                    # Without this the server sends CORS headers only to strem.io origins, and the UI below is served from neither
                    NO_CORS = "1";
                    # nginx owns TLS here; left on, the server opens 12470 and fetches a certificate for it from api.strem.io
                    NO_HTTPS_SERVER = "1";
                    # Nothing casts from a headless box, and leaving it on has the server scan the network for receivers
                    CASTING_DISABLED = "1";
                };

                # It shells out to `ps` while probing hardware transcoding at startup, and dies on the spawn if it is missing
                path = [ pkgs.procps ];

                serviceConfig = {
                    ExecStart = "${lib.getExe pkgs.nodejs} ${server}";
                    DynamicUser = true;
                    StateDirectory = "stremio-server";
                    Restart = "on-failure";
                };
            };

            # Not /Storage/Services/Stremio: that is stremio-export's directory of daily account exports, and the marker below would
            # take the whole of it out of every backup
            environment.persistence."/Storage/Services/Stremio-Server".directories = [
                "/var/lib/private/stremio-server"
            ];

            systemd.tmpfiles.settings."Stremio-Server" = {
                "/Storage/Services/Stremio-Server".d = {
                    user = "root";
                    group = "root";
                    mode = "0755";
                };
                "/Storage/Services/Stremio-Server/.nobackup".f = {
                    user = "root";
                    group = "root";
                    mode = "0644";
                };
            };
        }

        # Reverse Proxy ##############################################################################################################################
        {
            # Two names rather than one: the UI resolves every server call against the root of the streaming server URL, so putting the
            # server under a path on the UI's own name would drop the path and 404.
            nginx-vhosts.stremio = {
                domain = webDomain;
                port = serverPort; # Unused -- this vhost serves files, and the option is mandatory
                extraConfig = {
                    root = "${web}";
                    locations = {
                        # The address above is only the UI's own default; the profile the wasm core starts from still carries
                        # 127.0.0.1:11470, the viewer's own machine, so an unaimed visit reports the server as unavailable. Handing the
                        # UI the URL it already calls its default makes it adopt it silently rather than through a modal, and the guard
                        # keeps the redirect from looping.
                        "= /" = {
                            index = "index.html";
                            tryFiles = "$uri $uri/ /index.html";
                            extraConfig = ''
                                if ($arg_streamingServerUrl = "") {
                                    return 307 https://${webDomain}/?streamingServerUrl=https%3A%2F%2F${serverDomain}%2F;
                                }
                            '';
                        };

                        "= /service-worker.js" = {
                            alias = "${serviceWorkerKillSwitch}";
                            extraConfig = "add_header Cache-Control \"no-store\";";
                        };

                        # The UI is a single-page app, so an unknown path has to come back as index.html
                        "/" = {
                            index = "index.html";
                            tryFiles = "$uri $uri/ /index.html";
                        };
                    };
                };
            };

            nginx-vhosts.stremio-server = {
                domain = serverDomain;
                port = serverPort;
                extraConfig.locations = {
                    # server.js reads the protocol off its own socket, so its redirect here hands the browser an http:// URL that the
                    # HTTPS UI refuses as mixed content; send people to the UI already pointed at this server instead
                    "= /".return = "307 https://${webDomain}/?streamingServerUrl=https%3A%2F%2F${serverDomain}%2F";

                    "/" = {
                        proxyPass = "http://127.0.0.1:${toString serverPort}";
                        proxyWebsockets = true;
                        recommendedProxySettings = true;
                        # Video is streamed rather than served as a page: buffering it stalls playback, and a paused player idles the
                        # connection well past nginx's 60s default
                        extraConfig = ''
                            proxy_buffering off;
                            proxy_request_buffering off;
                            client_max_body_size 0;
                            proxy_read_timeout 1h;
                            proxy_send_timeout 1h;
                        '';
                    };
                };
            };
        }
    ];
}
