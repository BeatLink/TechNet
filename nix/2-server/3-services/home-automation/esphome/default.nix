{
    inputs,
    config,
    ...
}:
{
    # Enable the service -----------------------------------------------------------------------------------------------------------------------
    services.esphome = {
        enable = true;
        port = 6052;
        address = "localhost";
        usePing = true;
    };

    environment.persistence."/Storage/Services/ESPHome".directories = [ "/var/lib/esphome" ];

    # Configure authentiation ------------------------------------------------------------------------------------------------------------------
    sops.secrets.esphome_env.sopsFile = "${inputs.self}/secrets/2-server/esphome.yaml";
    systemd.services.esphome.serviceConfig = {
        EnvironmentFile = config.sops.secrets.esphome_env.path;
    };

    # Setup Nginx Virtual Host and Pi-Hole -----------------------------------------------------------------------------------------------------
    nginx-vhosts.esphome = {
        domain = "esphome.heimdall.technet";
        port = 6052;
    };
}
