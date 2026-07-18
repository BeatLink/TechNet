# Home Assistant
#
# Home Assistant is the home automation server. It manages lighting and energy management, safety and security.
#

{ pkgs, ... }:
{
    services.home-assistant = {
        enable = true;
        config = null;
        #{
        #    "automation ui" = "!include automations.yaml";
        #    "scene ui" = "!include scenes.yaml";
        #    "script ui" = "!include scripts.yaml";
        #};
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
            "mqtt"
            "open_meteo"
            "vlc_telnet"
            "motioneye"
            "traccar"
            "command_line"
            "wyoming"
        ];
        customComponents =   [
            (pkgs.home-assistant-custom-components.frigate.overrideAttrs (old: {
                pytestFlagsArray = (old.pytestFlagsArray or [ ]) ++ [
                    "--deselect=tests/test_integration_services.py::test_review_summarize_service_version_check"
                    "--deselect=tests/test_integration_services.py::test_review_summarize_service_no_integration"
                ];
            }))

        ];
        customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [
            mushroom
            horizon-card
            advanced-camera-card
            mini-graph-card
            mini-media-player
        ];

    };

    systemd.tmpfiles.rules = [
        "d /Storage/Services/Home-Assistant 0750 hass hass - -"
        "Z /Storage/Services/Home-Assistant 0750 hass hass - -"
        "a+ /Storage/Files/Music - - - - u:hass:rx"
        "a+ /Storage/Files/Sounds - - - - u:hass:rx"
    ];

    nginx-vhosts.home-assistant = {
        domain = "home-assistant.heimdall.technet";
        port = 8123;
    };

    security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          var allowedUnits = ["go2rtc.service", "frigate.service"];
          if (action.id == "org.freedesktop.systemd1.manage-units" &&
              allowedUnits.indexOf(action.lookup("unit")) !== -1 &&
              subject.user == "hass") {
            return polkit.Result.YES;
          }
        });
    '';
}
