# LNXlink
#
# Publishes Heimdall itself into Home Assistant over MQTT -- CPU, memory, disk,
# temperature, network and systemd state as sensors, and shutdown/suspend/restart
# as buttons. Home Assistant picks all of it up through MQTT discovery, so there
# is nothing to configure on that side.
#
# https://bkbilly.gitbook.io/lnxlink

{ config, pkgs, ... }:
{
    # The broker account is declared in mosquitto/broker.nix alongside the other users;
    # here the same password is rendered into the environment file systemd hands
    # to the service, so the credential never reaches the world-readable store.
    sops.templates."lnxlink.env".content = ''
        LNXLINK_MQTT_USER=lnxlink-heimdall
        LNXLINK_MQTT_PASS=${config.sops.placeholder.mosquitto_lnxlink_heimdall_password}
    '';

    services.lnxlink = {
        enable = true;

        # A system service, not the module's default user service: Heimdall has no
        # graphical session for the session-bus modules to attach to.
        mode = "system";
        user = "root";

        # The desktop build's X11, audio and GIO dependencies buy nothing on a
        # headless machine. Everything still wanted here -- D-Bus, Docker, the
        # REST API -- stays in.
        package = pkgs.lnxlink.override {
            withX11 = false;
            withAudio = false;
            withGio = false;
        };

        environmentFile = config.sops.templates."lnxlink.env".path;

        settings = {
            mqtt = {
                # Straight to the local broker; nginx's TLS endpoint exists for
                # Odin, which has to come in over the network.
                server = "127.0.0.1";
                port = 1883;
                prefix = "lnxlink";
                clientId = "Heimdall";
                discovery.enabled = true;
            };

            # Server metrics do not need the five second default.
            update_interval = 30;

            # Anything that errors on load disables itself, so this list is only
            # the modules that would otherwise happily run and should not.
            #
            #   restful       serves an unauthenticated HTTP API on 0.0.0.0:8112.
            #                 wireguard0 is a trusted interface, so that is every
            #                 peer in the TechNet holding a shutdown button for a
            #                 service running as root. MQTT is the only interface
            #                 this should have.
            #   beacondb      scans the surrounding access points and uploads them
            #                 to a public geolocation service.
            #   power_profile logs a D-Bus failure on every poll; Heimdall has no
            #                 power-profiles-daemon.
            #
            # The rest is hardware Heimdall does not have or a session it does not
            # run.
            exclude = [
                "battery"
                "beacondb"
                "bluetooth"
                "brightness"
                "camera_used"
                "display_env"
                "gamepad"
                "gpu"
                "idle"
                "media"
                "microphone_used"
                "mouse"
                "notify"
                "power_profile"
                "restful"
                "speaker_used"
                "speech_recognition"
                "steam"
                "webcam"
                "wifi"
                "wol"
            ];
        };
    };

    environment.persistence."/Storage/Services/LNXlink".directories = [ "/var/lib/lnxlink" ];
}
