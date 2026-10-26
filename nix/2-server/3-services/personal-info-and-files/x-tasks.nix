# X-Tasks ############################################################################################################################################
#
# The X-Tasks web app and sync server, which the desktop and Android apps sync with using the token in secrets/2-server/x-tasks.yaml.
#
{
    config,
    inputs,
    pkgs,
    ...
}:
{
    imports = [ inputs.x-tasks.nixosModules.default ];

    sops.secrets.x_tasks_access_token.sopsFile = "${config.technet.secrets.path}/x-tasks.yaml";

    services.x-tasks-server = {
        enable = true;
        port = 9002;
        tokenFile = config.sops.secrets.x_tasks_access_token.path;
    };

    environment.persistence."/Storage/Services/X-Tasks".directories = [
        "/var/lib/private/x-tasks-server"
    ];

    # Impermanence leaves the persisted copy world-readable, exposing the task database to every local account
    systemd.services.x-tasks-server.serviceConfig.ExecStartPre = [
        "+${pkgs.coreutils}/bin/chmod 0700 /Storage/Services/X-Tasks"
    ];

    nginx-vhosts.x-tasks = {
        domain = "tasks.heimdall.technet";
        port = 9002;
    };
}
