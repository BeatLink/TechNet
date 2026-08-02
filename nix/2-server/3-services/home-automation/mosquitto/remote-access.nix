{ config, ... }:
{
    # The broker itself stays bound to 127.0.0.1. Odin gets to it the same way it
    # gets to every other service here: through nginx on a *.heimdall.technet
    # name, terminating TLS with the TechNet certificate.
    #
    # This is a `stream` server rather than a virtualHost because MQTT is not
    # HTTP -- LNXlink builds a plain paho client with no websocket transport, so
    # nginx-vhosts.nix cannot carry it and nginx proxies the TCP session instead.
    # 8883 is the registered port for MQTT over TLS. (The browser client does
    # speak websockets, and is carried by an ordinary vhost -- see web-ui.nix.)
    #
    # 8883 is deliberately *not* in `allowedTCPPorts`: it is reachable because
    # wireguard0 is a trusted interface, which means every peer in the TechNet
    # can open a session to it. Authentication and the per-user ACLs in
    # broker.nix are what stand between a peer and the topic tree, not the
    # firewall.
    services.nginx.streamConfig = ''
        server {
            listen 8883 ssl;
            ssl_certificate ${config.sops.secrets.https_certificate.path};
            ssl_certificate_key ${config.sops.secrets.https_certificate_key.path};
            proxy_pass 127.0.0.1:1883;
        }
    '';

    # nginx-vhosts.nix does this for every vhost it manages; a stream server is
    # not one, so the name is pointed at Heimdall by hand.
    services.pihole-ftl.settings.dns.cnameRecords = [ "mqtt.heimdall.technet,heimdall.technet" ];
}
