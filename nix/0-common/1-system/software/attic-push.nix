# Attic Push #########################################################################################################################################
#
# The endpoint and token this host pushes to Heimdall's cache with. X-Nix's TechNet cache does the pushing (push_command in x-nix.nix): it pushes
# every closure it builds and pushes again any its checks find the cache still lacks paths of (retry_push), so no watcher or retry runs here.
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
        enable = lib.mkEnableOption "the endpoint and token for pushing to Heimdall's Attic cache";

        configDir = lib.mkOption {
            type = lib.types.path;
            readOnly = true;
            description = "XDG_CONFIG_HOME for any service on this host that pushes to the cache, so they share one endpoint and token.";
        };
    };

    config = lib.mkIf cfg.enable {
        technet.atticPush.configDir = atticConfig;

        # Each pusher has its own token, made with `atticadm make-token --sub <host>`, so Attic records which host uploaded each path.
        sops.secrets.attic_push_token.sopsFile = "${config.technet.secrets.path}/attic-push.yaml";
    };
}
