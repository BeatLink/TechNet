{ inputs, ... }:
{
    # Vigil's `traccar` plugin authenticates as a dedicated read-only user to
    # check device staleness via /api/devices. Traccar has no declarative
    # user provisioning (no config-file user list, no CLI, users live only in
    # its database) — unlike the other services' vigil accounts, this one
    # must be created once by hand in the Traccar UI (Settings > Users > add
    # "vigil", uncheck Administrator, grant it read access to the devices to
    # monitor), with its password then stored at
    # secrets/2-server/traccar.yaml as `vigil_password` to match.
    sops.secrets.traccar_vigil_password = {
        sopsFile = "${inputs.self}/secrets/2-server/traccar.yaml";
        owner = "vigil-access";
    };

    services.traccar = {
        enable = true;
        settings = {
            web = {
                port = "9280";
                url = "traccar.heimdall.technet";
            };
            protocols.enable = "";
        };
    };
    environment.persistence."/Storage/Services/Traccar".directories = [ "/var/lib/private/traccar" ];
    nginx-vhosts.traccar = {
        domain = "traccar.heimdall.technet";
        port = 9280;
    };
}
