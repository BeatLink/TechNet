# Wi-Fi
#
# A fallback path onto the network for when the wired link is down or the machine has moved: wpa_supplicant joins the fleet's known Wi-Fi networks and
# networkd takes an address by DHCP. NetworkManager's profiles in 0-common are not used here because this host's network stack is systemd-networkd.
#

{ config, ... }:
let
    commonSecrets = "${config.technet.secrets.commonPath}/networkmanager.yaml";
in
{
    sops.secrets = {
        technet_wifi_password.sopsFile = commonSecrets;
        family_home_wifi_password.sopsFile = commonSecrets;
        thor_wifi_password.sopsFile = commonSecrets;
    };

    sops.templates."wpa_supplicant-secrets.conf" = {
        content = ''
            technet_wifi_password=${config.sops.placeholder.technet_wifi_password}
            family_home_wifi_password=${config.sops.placeholder.family_home_wifi_password}
            thor_wifi_password=${config.sops.placeholder.thor_wifi_password}
        '';
        owner = "wpa_supplicant";
    };

    networking.wireless = {
        enable = true;
        secretsFile = config.sops.templates."wpa_supplicant-secrets.conf".path;
        networks = {
            "TechNet Wi-Fi" = {
                pskRaw = "ext:technet_wifi_password";
                hidden = true;
                priority = 100;
            };
            "Digicel_5G_WiFi_5tDQ" = {
                pskRaw = "ext:family_home_wifi_password";
                priority = 100;
            };
            "Thor" = {
                pskRaw = "ext:thor_wifi_password";
                priority = 50;
            };
        };
    };

    systemd.network.networks."02-wifi" = {
        matchConfig.WLANInterfaceType = "station";
        networkConfig.DHCP = "ipv4";
        # A higher metric than the wired default route, so Wi-Fi only carries traffic when lan0 is down
        dhcpV4Config.RouteMetric = 2048;
        linkConfig.RequiredForOnline = "no";
    };
}
