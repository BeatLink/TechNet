# Minimal recovery/bootstrap image: flashed onto a bare ESP8285 to get it
# talking on wifi with OTA enabled, before handing it its real device config.
# Deliberately standalone -- it predates the device even having a name, so it
# doesn't pull in `1-common.yaml` (HA API key, dual wifi networks, etc).
{
    esphome = {
        name = "esphome-ota-update";
        name_add_mac_suffix = true;
    };
    esp8266.board = "esp8285";
    # Networking ---------------------------------------------------------------
    wifi = {
        ssid = "!secret wifi_ssid";
        password = "!secret wifi_password";
        ap = {
            ssid = "ESPHome OTA Update Hotspot";
            password = "!secret wifi_password";
        };
    };
    captive_portal = null;
    web_server.port = 80;
    # APIs and Interfaces --------------------------------------------------------
    ota = [
        { platform = "web_server"; }
        {
            platform = "esphome";
            password = "!secret ota_password";
        }
    ];
}
