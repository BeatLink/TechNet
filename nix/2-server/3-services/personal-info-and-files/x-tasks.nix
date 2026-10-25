# X-Tasks ############################################################################################################################################
#
# The X-Tasks web app and sync server, which the desktop and Android apps sync with using the token in secrets/2-server/x-tasks.yaml.
#
{ config, inputs, ... }:
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

    nginx-vhosts.x-tasks = {
        domain = "x-tasks.heimdall.technet";
        port = 9002;
    };
}
