# Home Assistant
#
# Home Assistant is the home automation server. It manages lighting and energy management, safety and security.
#

{ pkgs, ... }:
{
    services.home-assistant = {
        enable = true;
        config = null;
        lovelaceConfig = null;
        configDir = "/Storage/Services/Home-Assistant/config";
        extraComponents = [
            "esphome"
            "met"
            "radio_browser"
            "ssdp"
            "stream"
            "mobile_app"
            "dhcp"
            "go2rtc"
            "open_meteo"
            "vlc_telnet"
            "uptime_kuma"
            "motioneye"
            "traccar"
        ];
        customComponents = with pkgs.home-assistant-custom-components; [
            (pkgs.home-assistant-custom-components.frigate.overrideAttrs (old: {
                pytestFlagsArray = (old.pytestFlagsArray or [ ]) ++ [
                    "--deselect=tests/test_integration_services.py::test_review_summarize_service_version_check"
                    "--deselect=tests/test_integration_services.py::test_review_summarize_service_no_integration"
                ];
            }))
            mqtt

        ];
        customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [
            mushroom
            horizon-card
            advanced-camera-card
            mini-graph-card
            mini-media-player
        ];

    };

    /*
      virtualisation.arion.projects.home-assistant = {
          serviceName = "home-assistant-old";
          settings = {
              services = {
                  home-assistant.service = {
                      image = "ghcr.io/home-assistant/home-assistant:stable";
                      container_name = "home-assistant-old";
                      restart = "always";
                      volumes = [
                          "/Storage/Services/Homeassistant/config:/config"
                          "/Storage/Services/Homeassistant/media:/media"
                          "/Storage/Files/Music:/music"
                          "/Storage/Files/Sounds:/sounds"
                      ];
                      environment = {
                          "TZ" = "America/Jamaica";
                      };
                      expose = [
                      ];
                      networks = [
                          "nginx-proxy-manager_public"
                      ];
                      ports = [
                          "8124:8123"
                          "9171:9170"
                          "1901:1900"
                          "5354:5353"
                      ];
                      extra_hosts = [
                          "host.docker.internal:host-gateway"
                      ];
                  };
              };
              networks = {
                  nginx-proxy-manager_public = {
                      external = true;
                  };
              };
          };
      };
    */

    nginx-vhosts.home-assistant = {
        domain = "home-assistant.heimdall.technet";
        port = 8123;
    };

    /*
      nginx-vhosts.home-assistant = {
          domain = "home-assistant.heimdall.technet";
          port = 8124;
      };
    */
}
