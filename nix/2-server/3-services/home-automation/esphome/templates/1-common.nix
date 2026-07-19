# Configuration common to every device.
#
# Included by each `2-base-*` hardware profile, so everything here lands on all
# devices: wifi, the Home Assistant API, the onboard web server, OTA and logging.
{
    substitutions = {
        wifi_fast_connect = "true";
        friendly_name = "";
        area = "";
        timezone = "America/Jamaica";
        sntp_update_interval = "1h";
        log_level = "INFO";
    };
    esphome = {
        name = "\${name}";
        friendly_name = "\${friendly_name}";
        name_add_mac_suffix = false;
    };
    # Networking ---------------------------------------------------------------
    wifi = {
        min_auth_mode = "WPA2";
        # Default networks, tried in order.
        networks = [
            {
                ssid = "!secret wifi_ssid";
                password = "!secret wifi_password";
            }
            {
                ssid = "!secret wifi_maypen_ssid";
                password = "!secret wifi_maypen_password";
            }
        ];
        # Fallback hotspot (captive portal) for when wifi association fails.
        ap = {
            ssid = "\${friendly_name} Hotspot";
            password = "!secret wifi_password";
        };
        domain = ".lan";
        use_address = "\${name}.lan";
    };
    network.enable_ipv6 = false;
    mdns.disabled = true;
    # API ----------------------------------------------------------------------
    api.encryption.key = "!secret api_encryption_key";
    # Web server ---------------------------------------------------------------
    web_server = {
        port = 80;
        local = true;
        version = 3;
        auth = {
            username = "!secret web_username";
            password = "!secret web_password";
        };
    };
    # OTA updates --------------------------------------------------------------
    ota = [
        { platform = "web_server"; }
        {
            platform = "esphome";
            password = "!secret ota_password";
        }
    ];
    # Logging and metrics ------------------------------------------------------
    logger.level = "INFO";
}
