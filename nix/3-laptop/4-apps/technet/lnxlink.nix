# LNXlink
#
# Publishes Odin into Home Assistant over MQTT -- battery, CPU, memory, disks,
# wifi, the media player, idle state and notifications, plus controls for
# suspend, shutdown and screen blanking. Home Assistant discovers all of it, so
# there is nothing to configure on that side.
#
# https://bkbilly.gitbook.io/lnxlink

{ config, inputs, ... }:
{
    # The Home Manager module takes its package from the system's `pkgs`, so the
    # flake's overlay has to be applied here rather than by its NixOS module.
    nixpkgs.overlays = [ inputs.lnxlink.overlays.default ];

    # Same password as the lnxlink-odin account in Heimdall's mosquitto.nix.
    # Owned by beatlink because the unit is a user service.
    sops.secrets.lnxlink_mqtt_password = {
        sopsFile = "${config.technet.secrets.path}/lnxlink.yaml";
        key = "odin_password";
        owner = "beatlink";
    };

    sops.templates."lnxlink.env" = {
        owner = "beatlink";
        content = ''
            LNXLINK_MQTT_USER=lnxlink-odin
            LNXLINK_MQTT_PASS=${config.sops.placeholder.lnxlink_mqtt_password}
        '';
    };

    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            services.lnxlink = {
                enable = true;
                package = pkgs.lnxlink;
                environmentFile = config.sops.templates."lnxlink.env".path;

                settings = {
                    mqtt = {
                        # The broker is bound to localhost on Heimdall; this is
                        # the nginx stream endpoint in front of it, terminating
                        # TLS with the TechNet certificate. See mosquitto.nix.
                        server = "mqtt.heimdall.technet";
                        port = 8883;
                        prefix = "lnxlink";
                        clientId = "Odin";
                        auth.tls = true;
                        discovery.enabled = true;
                    };

                    update_interval = 5;

                    # restful serves an unauthenticated HTTP API on 0.0.0.0:8112
                    # and beacondb uploads the surrounding access points to a
                    # public geolocation service. Neither is wanted; Home
                    # Assistant reaches this over MQTT.
                    exclude = [
                        "beacondb"
                        "gpu"
                        "restful"
                        "speech_recognition"
                        "webcam"
                    ];
                };
            };

            home.persistence."/Storage/Apps/TechNet/LNXlink".directories = [
                ".local/state/lnxlink"
            ];
        };
}
