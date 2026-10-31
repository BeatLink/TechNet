# X-Nix ##############################################################################################################################################
#
# The NixOS deployment portal at nix.heimdall.technet, watching Heimdall against the flake and its Nix store, and the fleet's closures in the
# Attic cache, beside X-Monitor, which still updates, switches, collects, builds and pushes.
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

    # Collect Garbage runs the same collection the weekly timer does.
    gcOptions = config.nix.gc.options;

    # X-Monitor's nightly builds root each closure here, and drop those kept only in the cache.
    buildRoots = "/var/lib/x-monitor-agent/build-roots";
    fleet = [
        "Heimdall"
        "Odin"
        "Ragnarok"
        "Thor"
    ];
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
            # The same store policy as X-Monitor's nix_gc monitors.
            gc = {
                max_age = "2w";
                warning = 90;
                threshold = 96;
                max_generation_age = "30d";
                gc_args = builtins.filter (a: a != "") (lib.splitString " " gcOptions);
            };
        };
        # Checked only, and less often than X-Monitor's hourly check: X-Monitor still builds and pushes them, and holds the Attic token and the
        # build roots.
        caches.technet = {
            name = "TechNet";
            interval = "6h";
            flake = config.technet.flake;
            configurations = fleet;
            cache_url = "https://attic.heimdall.technet/technet";
            build_root_dir = buildRoots;
            build_links = lib.genAttrs fleet (host: "${lib.toLower host}-nixos-deployment");
            drop_pushed = [
                "Odin"
                "Ragnarok"
                "Thor"
            ];
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
                {
                    command = "/run/current-system/sw/bin/nix-collect-garbage ${gcOptions}";
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
