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
    options.technet.atticPush.enable = lib.mkEnableOption "uploading locally built paths to Heimdall's Attic cache";

    config = lib.mkIf cfg.enable {
        # The same token for every pusher: Attic scopes by cache, not by who is writing, so a per-host token would buy nothing.
        sops.secrets.attic_push_token.sopsFile = "${config.technet.secrets.commonPath}/attic-push.yaml";

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
                Environment = [ "XDG_CONFIG_HOME=${atticConfig}" ];

                # Heimdall being unreachable is ordinary here, so the watcher retries forever rather than giving up and leaving the cache cold.
                Restart = "always";
                RestartSec = 30;

                # Uploading is never worth slowing a build or a desktop for.
                Nice = 19;
                IOSchedulingClass = "idle";
            };
        };
    };
}
