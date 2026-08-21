{ pkgs, config, ... }:
{
    # Vigil and LNXlink get plaintext passwords rather than hashes because the
    # same value has to be handed to the client as well: Vigil reads it with
    # `password_command`, LNXlink through its environment file. The module hashes
    # them into the generated password file at startup. Home Assistant and
    # Frigate hold their own copies, so only the hash is needed here.
    sops.secrets.mosquitto_vigil_password = {
        sopsFile = "${config.technet.secrets.path}/mosquitto.yaml";
        group = "vigil-monitor";                                        # Read by whichever Vigil transport runs the `cat` — the agent today, vigil-access as fallback
        mode = "0440";
    };

    sops.secrets.mosquitto_homeassistant_password_hash = {
        sopsFile = "${config.technet.secrets.path}/mosquitto.yaml";
        key = "homeassistant_password_hash";
    };
    sops.secrets.mosquitto_frigate_password_hash = {
        sopsFile = "${config.technet.secrets.path}/mosquitto.yaml";
        key = "frigate_password_hash";
    };

    # The two LNXlink instances -- see lnxlink.nix here and on Odin.
    sops.secrets.mosquitto_lnxlink_heimdall_password = {
        sopsFile = "${config.technet.secrets.path}/lnxlink.yaml";
        key = "heimdall_password";
    };
    sops.secrets.mosquitto_lnxlink_odin_password = {
        sopsFile = "${config.technet.secrets.path}/lnxlink.yaml";
        key = "odin_password";
    };

    environment.systemPackages = [
        pkgs.mosquitto # mosquitto_sub / mosquitto_pub
        pkgs.mqttui # live topic tree in a terminal, for when the browser is not to hand
    ];

    services.mosquitto = {
        enable = true;
        listeners = [
            {
                address = "127.0.0.1";
                port = 1883;
                users = {
                    # Home Assistant's own side of this connection is *not*
                    # declared anywhere: HA dropped broker settings from YAML, so
                    # the host, username and password it presents live in its
                    # storage under /Storage/Services/Home-Assistant/config. Only
                    # the hash it is checked against is in this repo -- rebuilding
                    # HA from nothing means entering the credential again.
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
                        acl = [
                            "readwrite vigil/probe/#"
                            # The Frigate MQTT monitor reads the retained
                            # availability topic to prove Frigate's session is
                            # still up. One topic, read only -- Vigil has no
                            # business anywhere else under frigate/.
                            "read frigate/available"
                        ];
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
}
