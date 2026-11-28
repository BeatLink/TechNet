# X-Fitness ##########################################################################################################################################
#
# The X-Fitness web app and sync server. Its admins are the accounts file in secrets/2-server/x-fitness.yaml; browsers and devices sign in as them.
#
{
    config,
    inputs,
    pkgs,
    ...
}:
{
    imports = [ inputs.x-fitness.nixosModules.default ];

    sops.secrets.x_fitness_password_hash.sopsFile = "${config.technet.secrets.path}/x-fitness.yaml";

    services.x-fitness = {
        enable = true;
        port = 9003;
        passwordHashFile = config.sops.secrets.x_fitness_password_hash.path;
        # Where paired devices reach this server's sync, through nginx below.
        syncAddress = "https://fitness.heimdall.technet/api/";
    };

    environment.persistence."/Storage/Services/X-Fitness".directories = [
        "/var/lib/private/x-fitness"
    ];

    # Impermanence leaves the persisted copy world-readable, exposing the fitness database to every local account
    systemd.services.x-fitness.serviceConfig.ExecStartPre = [
        "+${pkgs.coreutils}/bin/chmod 0700 /Storage/Services/X-Fitness"
    ];

    nginx-vhosts.x-fitness = {
        domain = "fitness.heimdall.technet";
        port = 9003;
        extraConfig = {
            # A device's first sync sends every row it holds in one call, which can pass nginx's 10M default.
            extraConfig = "client_max_body_size 256m;";
        };
    };
}
