{
    services.mosquitto = {
        enable = true;
        listeners = [
            {
                address = "127.0.0.1";
                port = 1883;
                #acl = [ "pattern readwrite #" ];
                users = {
                    homeassistant = {
                        acl = [
                            "readwrite #"
                        ];
                        hashedPassword = "$7$101$JK9EsqBDvLxRjMPu$luaDg9rqveBv6MHKandjD41EbyR35WqLPRVlNDJjXDFizGzuQJ8EjUzO+PLYP7TnU2AdBcw69W2bb/L15vPbzw==";
                    };
                    frigate = {
                        acl = [
                            "readwrite #"
                        ];
                        hashedPassword = "$7$101$+xsfm3AJVBJe7pb8$QSxNsvFw8utqzzvaiZ0GXlp8HZQB1z0lj+EvRwbGwUbWJdkKNfUCNWrq90Vm+i/39csFiLuItsBAAYp+jEYeVA==";
                    };
                };
                #omitPasswordAuth = true;
                #settings.allow_anonymous = true;

            }
        ];
    };

    networking.firewall = {
        enable = true;
        allowedTCPPorts = [ 1883 ];
    };
}
