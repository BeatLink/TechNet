# X-Tasks ############################################################################################################################################
#
# The X-Tasks web app and sync server. Its admins are the accounts file in secrets/2-server/x-tasks.yaml; browsers and devices sign in as them.
#
{
    config,
    inputs,
    pkgs,
    ...
}:
{
    imports = [ inputs.x-tasks.nixosModules.default ];

    sops.secrets.x_tasks_password_hash.sopsFile = "${config.technet.secrets.path}/x-tasks.yaml";

    services.x-tasks-server = {
        enable = true;
        port = 9002;
        passwordHashFile = config.sops.secrets.x_tasks_password_hash.path;
        # Where paired devices reach this server's sync, through nginx below.
        syncAddress = "https://tasks.heimdall.technet/api/";
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
        extraConfig = {
            # A device's first sync sends every row it holds in one call, which can pass nginx's 10M default.
            extraConfig = "client_max_body_size 256m;";
        };
    };
}
