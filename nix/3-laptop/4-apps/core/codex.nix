# CODEX ##############################################################################################################################################
#
# The contexts and assistant app built in /Storage/Files/Projects/X-Tech-Laboratories/CODEX, installed from its GitHub flake.
# Its declared configuration names each token by its sops path, so the daemon reads it as beatlink and nothing secret reaches the store.
#
{
    config,
    inputs,
    lib,
    pkgs,
    ...
}:
let
    codex = inputs.codex.packages.${pkgs.stdenv.hostPlatform.system}.desktop;
    secret = name: config.sops.secrets.${name}.path;

    # scripts/set-codex-api-key.sh writes the engine keys here; a key is declared only once the file names it, since sops-nix fails on a missing one
    keysFile = "${config.technet.secrets.path}/codex.yaml";
    hasKey =
        name:
        builtins.pathExists keysFile
        && lib.any (line: lib.hasPrefix "${name}:" line) (
            lib.splitString "\n" (builtins.readFile keysFile)
        );
    hasAnthropicKey = hasKey "anthropic_api_key";

    # A token made on X-Tasks' Your account for CODEX; until it is saved, the old shared token is used
    hasXTasksToken = hasKey "x_tasks_codex_token";
in
{
    imports = [ inputs.codex.nixosModules.default ];

    sops.secrets = {
        # Claude Code still gets these through its managed MCP file, which sops-nix renders as root whoever owns them
        x_budget_mcp_token.owner = "beatlink";
        x_media_tracker_mcp_token.owner = "beatlink";

        anthropic_api_key = lib.mkIf hasAnthropicKey {
            sopsFile = keysFile;
            owner = "beatlink";
        };

        x_tasks_codex_token = lib.mkIf hasXTasksToken {
            sopsFile = keysFile;
            owner = "beatlink";
        };
    };

    programs.codex.declared = {
        engines = lib.mkIf hasAnthropicKey {
            "codex.anthropic".key_file = secret "anthropic_api_key";
        };
        sources = {
            "codex.x-tasks" = {
                address = "https://tasks.heimdall.technet";
                token_file = secret (if hasXTasksToken then "x_tasks_codex_token" else "x_tasks_access_token");
            };
            "codex.trilium" = {
                address = "https://trilium.heimdall.technet";
                token_file = secret "trilium_etapi_token";
            };
        };
        mcpServers = [
            {
                id = "x-fitness";
                name = "X-Fitness";
                address = "https://fitness.heimdall.technet/api/mcp";
                tokenFile = secret "x_fitness_mcp_token";
            }
            {
                id = "x-budget";
                name = "X-Budget";
                address = "https://budget.heimdall.technet/api/mcp";
                tokenFile = secret "x_budget_mcp_token";
            }
            {
                id = "x-media-tracker";
                name = "X-Media-Tracker";
                address = "https://media-tracker.heimdall.technet/api/mcp";
                tokenFile = secret "x_media_tracker_mcp_token";
            }
        ];
    };

    technet.desktop.apps.codex = {
        description = "CODEX";
        command = "${codex}/bin/codex-desktop";
        args = [ "--hidden" ];
        desktopFile = "${codex}/share/applications/codex.desktop";
        socket = "$HOME/.config/codex/SingletonSocket";
    };

    home-manager.users.beatlink.home = {
        packages = [ codex ];

        # Its data lives here, and the home rollback would otherwise blank it; the old CODEX's /Storage/Apps/AI/CODEX is not this app's.
        persistence."/Storage/Apps/Core/CODEX" = {
            directories = [
                ".config/codex"
            ];
        };
    };
}
