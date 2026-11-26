# X-Budget ###########################################################################################################################################
#
# The X-Budget web app and sync server. Its admins are the accounts file in secrets/2-server/x-budget.yaml; browsers and devices sign in as them.
#
{
    config,
    inputs,
    pkgs,
    ...
}:
{
    imports = [ inputs.x-budget.nixosModules.default ];

    sops.secrets.x_budget_password_hash.sopsFile = "${config.technet.secrets.path}/x-budget.yaml";

    services.x-budget = {
        enable = true;
        port = 9006;
        adminsFile = config.sops.secrets.x_budget_password_hash.path;
    };

    environment.persistence."/Storage/Services/X-Budget".directories = [
        "/var/lib/private/x-budget"
    ];

    # Impermanence leaves the persisted copy world-readable, exposing the budget database to every local account
    systemd.services.x-budget.serviceConfig.ExecStartPre = [
        "+${pkgs.coreutils}/bin/chmod 0700 /Storage/Services/X-Budget"
    ];

    nginx-vhosts.x-budget = {
        domain = "budget.heimdall.technet";
        port = 9006;
    };
}
