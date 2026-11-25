# X-Context ##########################################################################################################################################
#
# The X-Context web app and sync server. Its admins are the accounts file in secrets/2-server/x-context.yaml; browsers and devices sign in as them.
#
{
    config,
    inputs,
    pkgs,
    ...
}:
{
    imports = [ inputs.x-context.nixosModules.default ];

    sops.secrets.x_context_password_hash.sopsFile = "${config.technet.secrets.path}/x-context.yaml";

    services.x-context = {
        enable = true;
        port = 9005;
        passwordHashFile = config.sops.secrets.x_context_password_hash.path;
    };

    environment.persistence."/Storage/Services/X-Context".directories = [
        "/var/lib/private/x-context"
    ];

    # Impermanence leaves the persisted copy world-readable, exposing the context database to every local account
    systemd.services.x-context.serviceConfig.ExecStartPre = [
        "+${pkgs.coreutils}/bin/chmod 0700 /Storage/Services/X-Context"
    ];

    nginx-vhosts.x-context = {
        domain = "context.heimdall.technet";
        port = 9005;
    };
}
