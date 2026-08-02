{ pkgs, inputs, config, ... }:
{
    sops.secrets.mosquitto_vigil_password = {
        sopsFile = "${config.technet.secrets.path}/mosquitto.yaml";
        owner = "vigil-access";
    };

    sops.secrets.mosquitto_homeassistant_password_hash = {
        sopsFile = "${config.technet.secrets.path}/mosquitto.yaml";
        key = "homeassistant_password_hash";
    };
    sops.secrets.mosquitto_frigate_password_hash = {
        sopsFile = "${config.technet.secrets.path}/mosquitto.yaml";
        key = "frigate_password_hash";
    };

    # The two LNXlink instances. These are the plaintext passwords rather than
    # hashes because the same value has to be handed to LNXlink itself through
    # its environment file -- see lnxlink.nix here and on Odin. The module
    # hashes them into the generated password file at startup.
    sops.secrets.mosquitto_lnxlink_heimdall_password = {
        sopsFile = "${config.technet.secrets.path}/lnxlink.yaml";
        key = "heimdall_password";
    };
    sops.secrets.mosquitto_lnxlink_odin_password = {
        sopsFile = "${config.technet.secrets.path}/lnxlink.yaml";
        key = "odin_password";
    };

    environment.systemPackages = [ pkgs.mosquitto ];
    services.mosquitto = {
        enable = true;
        listeners = [
            {
                address = "127.0.0.1";
                port = 1883;
                users = {
                    homeassistant = {
                        acl = [
                            "readwrite homeassistant/#"
                            "readwrite frigate/#"
                            # LNXlink's discovery configs point Home Assistant at
                            # state topics under this prefix; without it the
                            # entities appear and then never update.
                            "readwrite lnxlink/#"
                        ];
                        hashedPasswordFile =
                            config.sops.secrets.mosquitto_homeassistant_password_hash.path;
                    };
                    frigate = {
                        acl = [ "readwrite frigate/#" ];
                        hashedPasswordFile =
                            config.sops.secrets.mosquitto_frigate_password_hash.path;
                    };

                    vigil = {
                        acl = [ "readwrite vigil/probe/#" ];
                        passwordFile = config.sops.secrets.mosquitto_vigil_password.path;
                    };

                    # LNXlink lowercases its own topic prefix, so the ACLs are
                    # lnxlink/<clientid> even though the clientId is capitalised.
                    # The second entry is the Home Assistant discovery topic each
                    # instance publishes its own entity configs to:
                    # homeassistant/<type>/lnxlink/<unique_id>/config.
                    lnxlink-heimdall = {
                        acl = [
                            "readwrite lnxlink/heimdall/#"
                            "readwrite homeassistant/+/lnxlink/#"
                        ];
                        passwordFile = config.sops.secrets.mosquitto_lnxlink_heimdall_password.path;
                    };
                    lnxlink-odin = {
                        acl = [
                            "readwrite lnxlink/odin/#"
                            "readwrite homeassistant/+/lnxlink/#"
                        ];
                        passwordFile = config.sops.secrets.mosquitto_lnxlink_odin_password.path;
                    };
                };
            }
        ];
    };

    # Reaching the broker from another host --------------------------------------------------------------------------------------------------
    # The broker itself stays bound to 127.0.0.1. Odin gets to it the same way
    # it gets to every other service here: through nginx on a *.heimdall.technet
    # name, terminating TLS with the TechNet certificate.
    #
    # This is a `stream` server rather than a virtualHost because MQTT is not
    # HTTP -- LNXlink builds a plain paho client with no websocket transport, so
    # nginx-vhosts.nix cannot carry it and nginx proxies the TCP session instead.
    # 8883 is the registered port for MQTT over TLS.
    services.nginx.streamConfig = ''
        server {
            listen 8883 ssl;
            ssl_certificate ${config.sops.secrets.https_certificate.path};
            ssl_certificate_key ${config.sops.secrets.https_certificate_key.path};
            proxy_pass 127.0.0.1:1883;
        }
    '';

    # nginx-vhosts.nix does this for every vhost it manages; a stream server is
    # not one, so the name is pointed at Heimdall by hand.
    services.pihole-ftl.settings.dns.cnameRecords = [ "mqtt.heimdall.technet,heimdall.technet" ];
}
