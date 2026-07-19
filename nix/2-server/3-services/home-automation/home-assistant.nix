# Home Assistant
#
# Home Assistant is the home automation server. It manages lighting and energy management, safety and security.
#

{ pkgs, ... }:
{
    services.home-assistant = {
        enable = true;

        # Phase 1 of the declarative migration: everything that lived in
        # configuration.yaml is now defined here. With configWritable left at its
        # default (false), the module renders this attrset to
        # /etc/home-assistant/configuration.yaml and symlinks it into configDir,
        # so the file is read-only and Nix is the single source of truth.
        #
        # Automations, scripts and scenes stay as !include directives pointing at
        # their own YAML files so they remain editable from the UI. Those are
        # later phases. The module's YAML renderer unquotes strings of the form
        # "!tag argument", which is what makes these includes work.
        config = {
            # Loads the default set of integrations. Do not remove.
            default_config = { };

            api = { };

            http = {
                use_x_forwarded_for = true;
                trusted_proxies = [ "127.0.0.0/8" ];
                ip_ban_enabled = false;
                login_attempts_threshold = 5;
            };

            automation = "!include automations.yaml";
            script = "!include scripts.yaml";
            scene = "!include scenes.yaml";

            homeassistant = {
                allowlist_external_dirs = [
                    "/Storage/Files/Music"
                    "/Storage/Files/Sounds"
                ];
                media_dirs = {
                    music = "/Storage/Files/Music";
                    sounds = "/Storage/Files/Sounds";
                };
            };

            sensor = [
                {
                    platform = "time_date";
                    display_options = [
                        "time"
                        "date"
                        "date_time"
                        "date_time_utc"
                        "date_time_iso"
                        "time_date"
                        "time_utc"
                    ];
                }
            ];

            alarm_control_panel = [
                {
                    platform = "manual";
                    unique_id = "home_alarm";
                    name = "Home Alarm";
                    code_arm_required = false;
                    arming_time = 30;
                    delay_time = 120;
                    trigger_time = 60;
                    arming_states = [ "armed_away" ];
                    disarmed.trigger_time = 0;
                }
            ];

            # Lovelace stays UI-managed for now; migrating it is a later phase.
            #
            # Two separate things have to be pinned to "storage" here:
            #
            #   mode           - without it the dashboards in .storage (Overview
            #                    and Map) stop rendering.
            #   resource_mode  - the module defaults this to "yaml" whenever
            #                    customLovelaceModules is non-empty, which would
            #                    make HA load only the Nix-generated resource list
            #                    and drop the HACS-installed maxi-media-player.
            #
            # In storage mode the generated lovelace.resources list below is
            # inert: HA reads .storage/lovelace_resources instead, which already
            # registers the modules by their unversioned filenames (the "?version"
            # query string Nix appends is only for cache busting, and the bare
            # filenames it omits do exist in www/nixos-lovelace-modules).
            #
            # Note that mini-graph-card and mini-media-player are built by Nix but
            # have never been registered as resources, so they are not loaded
            # today either. Worth resolving when Lovelace itself is migrated.
            lovelace = {
                mode = "storage";
                resource_mode = "storage";
            };

            # Inline theme definitions. These stay in config rather than using the
            # services.home-assistant.themes option, which takes theme *packages*
            # (pkgs.home-assistant-themes.*) and not inline colour definitions.
            frontend.themes = {
                normal = {
                    primary-color = "#00ACFF";
                    accent-color = "orange";
                };
                warning = {
                    primary-color = "orange";
                    accent-color = "orange";
                };
                danger = {
                    primary-color = "red";
                    accent-color = "red";
                };
            };

        };

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
            "mqtt"
            "open_meteo"
            "vlc_telnet"
            "motioneye"
            "traccar"
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
}
