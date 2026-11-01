# X-Nix ##############################################################################################################################################
#
# The NixOS deployment portal at nix.heimdall.technet, which runs the whole fleet's NixOS upkeep: it updates the flake, evaluates and builds every
# host's closure on Heimdall nightly and pushes it to the Attic cache, and switches each host once it drifts. Heimdall switches itself; every other host
# is switched from the cache by its own X-Nix agent (x-nix-agent.nix). The X-Nix modules carry their own sudo rules.
#
{
    config,
    inputs,
    lib,
    pkgs,
    ...
}:
let
    port = 7720;

    # The same store policy as X-Monitor's nix_gc monitors.
    gc = {
        max_age = "2w";
        warning = 90;
        threshold = 96;
        max_generation_age = "30d";
        gc_args = builtins.filter (a: a != "") (lib.splitString " " config.nix.gc.options);
    };

    # Each nightly build links its closure here, replacing the last one, so it stays rooted until deployed and attic-push-retry can find it. Readable by
    # all, since X-Monitor's cache check reads the closure lists of the targets kept only in the cache.
    buildRoots = "/var/lib/x-nix-build-roots";

    # Heimdall's Attic cache, where the other hosts' closures are kept once pushed instead of in Heimdall's own store.
    cacheUrl = "https://attic.heimdall.technet/technet";

    fleet = [
        "Heimdall"
        "Odin"
        "Ragnarok"
        "Thor"
    ];

    # Rolls a switch back unless X-Nix can still reach the host's agent once it has activated.
    safety = {
        magic_rollback = true;
        confirm_timeout = "2m";
    };

    # A host Heimdall evaluates and builds nightly, whose own agent switches it from the cache once it drifts and the cache holds the closure.
    remote =
        name: buildAt: tags:
        {
            inherit name tags;
            host = lib.toLower name;
            flake = config.technet.flake;
            configuration = name;
            eval_interval = "6h";
            eval_agent = "heimdall"; # Evaluating the flake on the 2GB Rock64 swaps it to death, and on the phone takes it out of service
            build_agent = "heimdall";
            build_at = buildAt;
            build_root_dir = buildRoots;
            cache_url = cacheUrl;
            switch_from_cache = true;
            auto_switch = true;
            auto_switch_after = "0";
            health_commands = [ "systemctl is-active --quiet sshd.service" ];
            inherit gc;
        }
        // safety;
in
{
    imports = [ inputs.x-nix.nixosModules.default ];

    sops.secrets.x_nix_password_hash.sopsFile = "${config.technet.secrets.path}/x-nix.yaml";

    # Write deploy key on the TechNet repo that Update Flake pushes the new lock with.
    sops.secrets.x_monitor_flake_deploy_key = {
        sopsFile = "${config.technet.secrets.path}/x-monitor.yaml";
        owner = "x-nix";
    };

    # The key the Provision page logs in to a machine being installed with; its public half goes in that machine's installer.
    sops.secrets.x_nix_provision_key = {
        sopsFile = "${config.technet.secrets.path}/x-nix.yaml";
        owner = "x-nix";
    };

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
            tags = [ "server" ];
            flake = config.technet.flake;
            eval_interval = "6h";
            rebuild_args = [
                "--no-write-lock-file"
                "-L"
            ];
            push_ssh_key = config.sops.secrets.x_monitor_flake_deploy_key.path; # Only this deployment pushes, so the key lives on Heimdall alone
            update_at = "02:00"; # The only thing that bumps flake.lock
            build_at = "04:00"; # The fleet's builds start after attic-gc at 03:00, whose database lock their uploads would contend with
            build_root_dir = buildRoots;
            auto_switch = true;
            auto_switch_after = "0";
            pre_switch_checks = [ "test \"$(df --output=pcent /boot | tail -1 | tr -dc 0-9)\" -lt 90" ];
            health_commands = [
                "systemctl is-active --quiet nginx.service"
                "systemctl is-active --quiet sshd.service"
                "systemctl is-active --quiet atticd.service"
            ];
            inherit gc;
        }
        // safety;
        deployments.odin = remote "Odin" "04:15" [ "desktop" ];
        deployments.ragnarok = remote "Ragnarok" "04:45" [ "arm" ];
        deployments.thor = remote "Thor" "04:30" [ "arm" ] // {
            interval = "30m"; # The phone wakes on battery only every half hour
            inhibit_sleep = true;
            post_switch = "systemctl is-active -q phosh.service || systemctl restart phosh.service"; # A switch that touches phosh stops it and leaves the screen dark
            health_commands = [
                "systemctl is-active --quiet sshd.service"
                "systemctl is-active --quiet phosh.service"
            ];
        };
        fleet.stages = [
            "@arm"
            "@desktop"
            "@server"
        ];
        provisioning = {
            ssh_key = config.sops.secrets.x_nix_provision_key.path;
            agent_url = "wss://nix.heimdall.technet/api/agent";
        };
        caches.technet = {
            name = "TechNet";
            flake = config.technet.flake;
            configurations = fleet;
            cache_url = cacheUrl;
            # A hand-made build replaces the nightly one's root, so it stays rooted until deployed like that one would.
            build_root_dir = buildRoots;
            build_links = lib.genAttrs fleet lib.toLower;
            # Once fully pushed these live only in the cache, and their deploys substitute them back from it.
            drop_pushed = [
                "Odin"
                "Ragnarok"
                "Thor"
            ];
            push_command = "env XDG_CONFIG_HOME=${config.technet.atticPush.configDir} ${pkgs.attic-client}/bin/attic push --jobs 2 technet";
        };
    };

    systemd.tmpfiles.settings."X-Nix".${buildRoots}.d = {
        user = "x-nix";
        group = "x-nix";
        mode = "0755";
    };

    environment.persistence."/Storage/Services/X-Nix".directories = [
        {
            directory = "/var/lib/x-nix";
            user = "x-nix";
            group = "x-nix";
            mode = "0700";
        }
        {
            directory = buildRoots;
            user = "x-nix";
            group = "x-nix";
            mode = "0755";
        }
    ];

    nginx-vhosts.x-nix = {
        domain = "nix.heimdall.technet";
        inherit port;
    };
}
