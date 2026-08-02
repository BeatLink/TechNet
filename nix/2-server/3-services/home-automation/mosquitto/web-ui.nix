{ pkgs, config, ... }:
let
    domain = "mqtt-web.heimdall.technet";

    # A browser cannot open a raw TCP socket, so the client needs a websockets
    # listener of its own. Local only -- it is reached through the vhost below,
    # which is where TLS happens.
    websocketPort = 9320;

    webClient = pkgs.callPackage ./web-client.nix {
        # The page is served from the same name that carries the websocket, so
        # the form comes up pointing at itself: wss://<domain>:443/mqtt.
        defaultHost = domain;
        defaultPort = 443;
        defaultTls = true;
        pageTitle = "TechNet MQTT";
    };
in
{
    # Typed into the browser by hand rather than held by a daemon, so this is a
    # password and not a hash -- `sops secrets/2-server/mosquitto.yaml` to read
    # it back.
    sops.secrets.mosquitto_webui_password = {
        sopsFile = "${config.technet.secrets.path}/mosquitto.yaml";
        key = "webui_password";
    };

    # A second listener, and therefore a second set of accounts: the module
    # always sets `per_listener_settings true` and writes a password and ACL file
    # per listener, so nothing that authenticates on 1883 can authenticate here.
    # The browser account is read-only by design -- publishing from a page left
    # open in a tab means turning on a light or overwriting a retained discovery
    # config by accident. Give it `readwrite` on a prefix if a test publisher is
    # ever wanted; don't widen it to `#`.
    services.mosquitto.listeners = [
        {
            address = "127.0.0.1";
            port = websocketPort;
            settings.protocol = "websockets";
            users.webui = {
                acl = [
                    "read #"
                    # `#` does not cover $SYS, and broker health -- uptime, client
                    # count, dropped messages -- is only there. Nothing else on
                    # this network reads it; Vigil's probe proves delivery works
                    # but says nothing about load.
                    "read $SYS/#"
                ];
                passwordFile = config.sops.secrets.mosquitto_webui_password.path;
            };
        }
    ];

    nginx-vhosts.mqtt-web = {
        inherit domain;
        port = websocketPort;
        extraConfig = {
            root = "${webClient}";
            # Replaces the generated `/` proxy entirely: this vhost serves files
            # and carries the websocket on one name, so `/` is the client and
            # /mqtt is the broker.
            locations = {
                "/" = {
                    index = "index.html";
                    tryFiles = "$uri $uri/ /index.html";
                };
                "/mqtt" = {
                    proxyPass = "http://127.0.0.1:${toString websocketPort}";
                    proxyWebsockets = true;
                    recommendedProxySettings = true;
                    # An idle MQTT connection sends nothing between keepalives,
                    # and nginx closes a proxied socket after 60s of silence by
                    # default -- which looks like the broker dropping the client.
                    extraConfig = "proxy_read_timeout 1h;";
                };
            };
        };
    };
}
