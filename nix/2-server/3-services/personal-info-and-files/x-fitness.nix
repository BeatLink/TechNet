# X-Fitness ##########################################################################################################################################
#
# The X-Fitness web app and sync server, which the desktop and Android apps sync with using the token in secrets/2-server/x-fitness.yaml.
#
{
    config,
    inputs,
    pkgs,
    ...
}:
{
    imports = [ inputs.x-fitness.nixosModules.default ];

    sops.secrets.x_fitness_access_token.sopsFile = "${config.technet.secrets.path}/x-fitness.yaml";

    services.x-fitness = {
        enable = true;
        port = 9003;
        tokenFile = config.sops.secrets.x_fitness_access_token.path;
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
    };
}
