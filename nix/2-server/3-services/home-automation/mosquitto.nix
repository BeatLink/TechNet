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
                };
            }
        ];
    };
}
