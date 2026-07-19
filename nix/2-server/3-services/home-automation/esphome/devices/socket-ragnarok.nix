# Ragnarok socket -- Athom smart plug v2, reachable over WireGuard.
#
# This plug lives off-site, so it joins the WireGuard tunnel rather than being
# addressed on the local `.lan` domain like the other devices.
{
    substitutions = {
        name = "socket-ragnarok";
        sensor_update_interval = "1s";
    };

    wifi.use_address = "socket-ragnarok.technet";

    packages.common = "!include 2-base-socket.yaml";

    wireguard = {
        private_key = "!secret wg-socket-ragnarok-privkey";
        address = "10.100.100.18";
        netmask = "255.255.255.0";
        peer_endpoint = "!secret wg-peer-endpoint";
        peer_port = 51820;
        peer_public_key = "!secret wg-peer-publickey";
        peer_allowed_ips = [ "10.100.100.0/24" ];
        peer_persistent_keepalive = "25s";
    };

    binary_sensor = [
        {
            platform = "wireguard";
            status = {
                name = "WireGuard Status";
                entity_category = "diagnostic";
            };
            enabled.name = "WireGuard Enabled";
        }
    ];

    text_sensor = [
        {
            platform = "version";
            name = "ESPHome Version";
        }
        {
            platform = "wireguard";
            address.name = "WireGuard Address";
        }
    ];
}
