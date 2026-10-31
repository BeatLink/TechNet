# X-Nix ##############################################################################################################################################
#
# The NixOS deployment portal at nix.heimdall.technet, watching every host against the flake with its Nix store and boot entries, and the
# fleet's closures in the Attic cache, beside X-Monitor, which still updates, switches, collects, builds and pushes.
#
# The login's password hash is its own, in secrets/2-server/x-nix.yaml, written by X-Nix's `npm run hash-password`. The other hosts are reached
# through their X-Nix agents (x-nix-agent.nix), each signing in with the key whose public line is declared under `agents` below.
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

    # The same store policy as X-Monitor's nix_gc monitors.
    gc = {
        max_age = "2w";
        warning = 90;
        threshold = 96;
        max_generation_age = "30d";
        gc_args = builtins.filter (a: a != "") (lib.splitString " " gcOptions);
    };

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
        # Each agent host's key, whose private half is in that host's x-nix-agent.yaml.
        agents = {
            odin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAQiMXi+0bu88Gkiuh+jXXEWROogQ0Uj/icnNZbAQrmJ x-nix-agent-odin";
            ragnarok = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGt5YJVNXiS5IiS4D3eCcD5BhqE3oJGcW4pxy1bnlzjA x-nix-agent-ragnarok";
            thor = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPrMmoZrvzNQGTQbvP3WYgROY2vjM6zQD4nJL4XsqQJA x-nix-agent-thor";
        };
        deployments.heimdall = {
            name = "Heimdall";
            flake = config.technet.flake;
            eval_interval = "6h";
            rebuild_args = deploy.forHost "Heimdall";
            inherit gc;
        };
        # Watched only: X-Monitor builds and switches these from here over SSH, as their deploy account.
        deployments.odin = {
            name = "Odin";
            host = "odin";
            flake = config.technet.flake;
            configuration = "Odin";
            eval_interval = "6h";
            inherit gc;
        };
        deployments.ragnarok = {
            name = "Ragnarok";
            host = "ragnarok";
            flake = config.technet.flake;
            configuration = "Ragnarok";
            eval_agent = "heimdall"; # Evaluating the flake on the 2GB Rock64 swaps it to death within seconds
            eval_interval = "6h";
            inherit gc;
        };
        deployments.thor = {
            name = "Thor";
            host = "thor";
            interval = "30m"; # The phone wakes on battery only every half hour
            flake = config.technet.flake;
            configuration = "Thor";
            eval_agent = "heimdall"; # Evaluating the flake on four 1.15GHz A53s takes the phone out of service for the duration
            eval_interval = "6h";
            inherit gc;
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
                # The Boot page reads systemd-boot's entries from the root-only /boot, and sets the one-shot next entry.
                {
                    command = "/run/current-system/sw/bin/bootctl list --json=short";
                    options = [ "NOPASSWD" ];
                }
                {
                    command = "/run/current-system/sw/bin/bootctl set-oneshot *";
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
