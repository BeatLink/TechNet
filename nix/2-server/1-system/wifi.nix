# Wi-Fi
#
# A fallback path onto the network: wpa_supplicant joins the fleet's known Wi-Fi networks and networkd takes an address by DHCP. When the
# internet has been down for 5 minutes, wifi-failover moves the card to the Thor hotspot, whose route outranks lan0's, and moves it back once
# the internet answers over lan0 again.
#

{ config, pkgs, ... }:
let
    commonSecrets = "${config.technet.secrets.commonPath}/networkmanager.yaml";

    # Runs wpa_cli against whichever interface is the Wi-Fi card.
    wifiCli = pkgs.writeShellScript "wifi-cli" ''
        for wireless in /sys/class/net/*/wireless; do
            exec ${pkgs.wpa_supplicant}/bin/wpa_cli -p /run/wpa_supplicant/control -i "$(basename "$(dirname "$wireless")")" "$@"
        done
    '';
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
        userControlled = true;
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
                # Joined only by wifi-failover, since its route takes over from lan0
                extraConfig = "disabled=1";
            };
        };
    };

    systemd.network.networks = {
        "02-wifi-thor" = {
            matchConfig = {
                WLANInterfaceType = "station";
                SSID = "Thor";
            };
            networkConfig.DHCP = "ipv4";
            dhcpV4Config.RouteMetric = 100;
            linkConfig.RequiredForOnline = "no";
        };
        "03-wifi" = {
            matchConfig.WLANInterfaceType = "station";
            networkConfig.DHCP = "ipv4";
            dhcpV4Config.RouteMetric = 2048;
            linkConfig.RequiredForOnline = "no";
        };
    };

    systemd.services.wifi-failover = {
        description = "Move Heimdall's internet onto the Thor hotspot while the home connection is down";
        wantedBy = [ "multi-user.target" ];
        after = [ "wpa_supplicant.service" ];
        path = [
            pkgs.iputils
            pkgs.gawk
        ];
        script = ''
            reachable() {
                for host in 1.1.1.1 8.8.8.8 9.9.9.9; do
                    ping -c 1 -W 5 "$@" "$host" > /dev/null 2>&1 && return 0
                done
                return 1
            }

            down_since=""
            while true; do
                if reachable; then
                    down_since=""
                else
                    down_since=''${down_since:-$(date +%s)}
                    if (( $(date +%s) - down_since >= 300 )); then
                        echo "No internet for 5 minutes, switching Wi-Fi to the Thor hotspot"
                        ${wifiCli} select_network "$(${wifiCli} list_networks | awk -F '\t' '$2 == "Thor" { print $1 }')"
                        until sleep 120 && reachable -I lan0; do :; done
                        echo "Internet is back over lan0, switching Wi-Fi back to the home networks"
                        ${wifiCli} reconfigure
                        down_since=""
                    fi
                fi
                sleep 60
            done
        '';
        serviceConfig = {
            ExecStopPost = "-${wifiCli} reconfigure";
            Restart = "always";
            RestartSec = 30;
        };
    };
}
