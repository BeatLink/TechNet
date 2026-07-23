{ pkgs, inputs, config, ... }:
{
    # Plaintext (not hashed): mosquitto's passwordFile is hashed by
    # mosquitto_passwd at activation time, unlike the other two users here
    # which store a pre-hashed value directly. Read by Vigil's `mosquitto`
    # plugin over SSH to run its publish/subscribe probe.
    sops.secrets.mosquitto_vigil_password = {
        sopsFile = "${inputs.self}/secrets/2-server/mosquitto.yaml";
        owner = "vigil-access";
    };

    # services.mosquitto only installs the broker itself; mosquitto_pub/_sub
    # (the CLI clients) come from the same package's `mosquitto-clients`
    # closure. Needed on PATH for Vigil's `mosquitto` plugin, which runs them
    # over SSH from vigil-access's shell.
    environment.systemPackages = [ pkgs.mosquitto ];

    services.mosquitto = {
        enable = true;
        listeners = [
            {
                address = "127.0.0.1";
                port = 1883;
                users = {
                    homeassistant = {
                        acl = [ "readwrite #" ];
                        hashedPassword = "$7$101$JK9EsqBDvLxRjMPu$luaDg9rqveBv6MHKandjD41EbyR35WqLPRVlNDJjXDFizGzuQJ8EjUzO+PLYP7TnU2AdBcw69W2bb/L15vPbzw==";
                    };
                    frigate = {
                        acl = [ "readwrite #" ];
                        hashedPassword = "$7$101$+xsfm3AJVBJe7pb8$QSxNsvFw8utqzzvaiZ0GXlp8HZQB1z0lj+EvRwbGwUbWJdkKNfUCNWrq90Vm+i/39csFiLuItsBAAYp+jEYeVA==";
                    };
                    # Scoped to the probe topic only, so a Vigil compromise
                    # (or this credential leaking any other way) cannot read
                    # or forge real device/HA traffic on any other topic.
                    vigil = {
                        acl = [ "readwrite vigil/probe/#" ];
                        passwordFile = config.sops.secrets.mosquitto_vigil_password.path;
                    };
                };
            }
        ];
    };
}
