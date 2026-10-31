# X-Nix ##############################################################################################################################################
#
# The NixOS deployment portal at nix.heimdall.technet, watching Heimdall against the flake beside X-Monitor, which still updates and switches it.
#
# The login's password hash is its own, in secrets/2-server/x-nix.yaml, written by X-Nix's `npm run hash-password`.
#
{
    config,
    inputs,
    lib,
    ...
}:
let
    port = 7720;

    deploy = import ../../../0-common/1-system/software/deploy.nix;
    deployArgs = lib.concatStringsSep " " (deploy.forHost "Heimdall");

    # sudoers ends a command spec at an unescaped colon.
    upgradeFlake = builtins.replaceStrings [ ":" ] [ "\\:" ] config.technet.flake;
in
{
    imports = [ inputs.x-nix.nixosModules.default ];

    sops.secrets.x_nix_password_hash.sopsFile = "${config.technet.secrets.path}/x-nix.yaml";

    services.x-nix = {
        enable = true;
        inherit port;
        serverName = "heimdall";
        passwordHashFile = config.sops.secrets.x_nix_password_hash.path;
        deployments.heimdall = {
            name = "Heimdall";
            flake = config.technet.flake;
            eval_interval = "6h";
            rebuild_args = deploy.forHost "Heimdall";
        };
    };

    security.sudo.extraRules = [
        {
            users = [ "x-nix" ];
            commands = [
                {
                    command = "/run/current-system/sw/bin/nixos-rebuild switch --flake ${upgradeFlake} ${deployArgs} --refresh";
                    options = [ "NOPASSWD" ];
                }
                {
                    command = "/run/current-system/sw/bin/systemctl reboot";
                    options = [ "NOPASSWD" ];
                }
            ];
        }
    ];

    environment.persistence."/Storage/Services/X-Nix".directories = [
        {
            directory = "/var/lib/x-nix";
            user = "x-nix";
            group = "x-nix";
            mode = "0700";
        }
    ];

    nginx-vhosts.x-nix = {
        domain = "nix.heimdall.technet";
        inherit port;
    };
}
