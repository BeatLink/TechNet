# Attic Push #########################################################################################################################################
#
# Uploads what this host builds to Heimdall's cache, so an overlay package is built once for the fleet instead of once per host per nixpkgs bump.
#
# Attic skips paths signed by an upstream cache, so watching the store mirrors what was built here and not the far larger set fetched from Hydra.
#
{
    config,
    lib,
    pkgs,
    ...
}:
let
    cfg = config.technet.atticPush;

    # attic looks under $XDG_CONFIG_HOME/attic; token-file keeps the credential itself out of the world-readable store.
    atticConfig = pkgs.writeTextDir "attic/config.toml" ''
        default-server = "technet"

        [servers.technet]
        endpoint = "https://attic.heimdall.technet/"
        token-file = "${config.sops.secrets.attic_push_token.path}"
    '';
in
{
    options.technet.atticPush = {
        enable = lib.mkEnableOption "uploading locally built paths to Heimdall's Attic cache";

        configDir = lib.mkOption {
            type = lib.types.path;
            readOnly = true;
            description = "XDG_CONFIG_HOME for any service on this host that pushes to the cache, so they share one endpoint and token.";
        };
    };

    config = lib.mkIf cfg.enable {
        technet.atticPush.configDir = atticConfig;

        # The same token for every pusher: Attic scopes by cache, not by who is writing, so a per-host token would buy nothing.
        sops.secrets.attic_push_token.sopsFile = "${config.technet.secrets.commonPath}/attic-push.yaml";

        # Watcher ####################################################################################################################################
        systemd.services.attic-watch-store = {
            description = "Upload newly built store paths to the TechNet Attic cache";
            wantedBy = [ "multi-user.target" ];
            wants = [ "network-online.target" ];
            after = [
                "network-online.target"
                "sops-install-secrets.service"
            ];

            serviceConfig = {
                ExecStart = "${pkgs.attic-client}/bin/attic watch-store technet";
                # Setting either threshold by hand also stops glibc raising them on the fly, which is what otherwise moves large blocks off
                # mmap and onto the heap, where freeing them returns nothing. Capping the arenas keeps 19 threads from each holding a free list.
                Environment = [
                    "XDG_CONFIG_HOME=${cfg.configDir}"
                    "MALLOC_ARENA_MAX=2"
                    "MALLOC_MMAP_THRESHOLD_=131072"
                    "MALLOC_TRIM_THRESHOLD_=131072"
                ];

                # Heimdall being unreachable is ordinary here, so the watcher retries forever rather than giving up and leaving the cache cold.
                Restart = "always";
                RestartSec = 30;

                # Uploading is never worth slowing a build or a desktop for.
                Nice = 19;
                IOSchedulingClass = "idle";
            };
        };

        # Recycling ##################################################################################################################################
        # Pushing a large closure grows the watcher's heap to match, and glibc hands almost none of it back: freed blocks stay on the allocator's
        # free lists, so the pages remain mapped and dirty and the kernel can only move them to swap. One host was found holding 6.6GiB of swap
        # against 18MiB resident, which is half its zram, and a full swap is what stops anything else being paged out.
        #
        # The allocator settings above should hold the growth down; this stays as a backstop, since the watcher keeps no state between paths and a
        # bounce costs only whatever is uploading at the time.
        systemd.services.attic-watch-store-recycle = {
            description = "Restart the Attic watcher so it returns its heap";
            serviceConfig = {
                Type = "oneshot";
                ExecStart = "${pkgs.systemd}/bin/systemctl try-restart attic-watch-store.service";
            };
        };

        systemd.timers.attic-watch-store-recycle = {
            description = "Hourly restart of the Attic watcher";
            wantedBy = [ "timers.target" ];
            timerConfig = {
                OnCalendar = "hourly";
                RandomizedDelaySec = "5m"; # The fleet pushes to one cache, so the hosts should not all bounce together
                Persistent = true;
            };
        };
    };
}
