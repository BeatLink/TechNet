# X-Nix ##############################################################################################################################################
#
# The NixOS deployment portal at nix.heimdall.technet, which runs the whole fleet's NixOS upkeep: it updates the flake, builds every host's closure
# nightly and pushes it to the Attic cache, switches each host once it drifts, and watches every host's Nix store and boot entries. X-Monitor only
# checks the outcome.
#
# The login's password hash is its own, in secrets/2-server/x-nix.yaml, written by X-Nix's `npm run hash-password`. The other hosts are reached
# through their X-Nix agents (x-nix-agent.nix), each signing in with the key whose public line is declared under `agents` below. Heimdall builds and
# switches them itself, over SSH as their deploy account, through technet-remote-switch (remote-deploy.nix).
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

    # A host Heimdall builds nightly and switches over SSH as soon as it drifts.
    remote = name: buildAt: {
        inherit name;
        host = lib.toLower name;
        flake = config.technet.flake;
        configuration = name;
        eval_interval = "6h";
        rebuild_args = deploy.forHost name;
        switch_agent = "heimdall";
        target_host = deploy.remote.${name}.target;
        rebuild_bin = "technet-remote-switch"; # Holds the target awake through the switch and runs its after-switch hook; see remote-deploy.nix
        build_at = buildAt;
        build_root_dir = buildRoots;
        cache_url = cacheUrl; # A closure the cache already holds is not fetched back just to root it
        auto_switch = true;
        auto_switch_after = "0"; # Switch as soon as drift is seen
        inherit gc;
    };
in
{
    imports = [ inputs.x-nix.nixosModules.default ];

    sops.secrets.x_nix_password_hash.sopsFile = "${config.technet.secrets.path}/x-nix.yaml";

    # Write deploy key on the TechNet repo that Update Flake pushes the new lock with.
    sops.secrets.x_monitor_flake_deploy_key = {
        sopsFile = "${config.technet.secrets.path}/x-monitor.yaml";
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
            flake = config.technet.flake;
            eval_interval = "6h";
            rebuild_args = deploy.forHost "Heimdall";
            push_ssh_key = config.sops.secrets.x_monitor_flake_deploy_key.path; # Only this deployment pushes, so the key lives on Heimdall alone
            update_at = "02:00"; # The only thing that bumps flake.lock
            build_at = "04:00"; # The fleet's builds start after attic-gc at 03:00, whose database lock their uploads would contend with
            build_root_dir = buildRoots;
            auto_switch = true;
            auto_switch_after = "0"; # Switch as soon as drift is seen
            inherit gc;
        };
        deployments.odin = remote "Odin" "04:15";
        deployments.ragnarok = remote "Ragnarok" "04:45" // {
            eval_agent = "heimdall"; # Evaluating the flake on the 2GB Rock64 swaps it to death within seconds
        };
        deployments.thor = remote "Thor" "04:30" // {
            interval = "30m"; # The phone wakes on battery only every half hour
            eval_agent = "heimdall"; # Evaluating the flake on four 1.15GHz A53s takes the phone out of service for the duration
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
