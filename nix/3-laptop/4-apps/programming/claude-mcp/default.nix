# Claude MCP #########################################################################################################################################
#
# Every MCP server Claude Code connects to, with the API tokens it sends them, rendered from sops into Claude Code's managed MCP file.
#
# The managed file is the only server list Claude Code reads, the VS Code extension's bundled CLI included, so a server added with `claude mcp add`
# is ignored; add it here instead. set-mcp-token stores a token pasted from an app's page in sops and lands it.
#
{ config, pkgs, ... }:
let
    tokens = [
        "x_nix_mcp_token"
        "x_backups_mcp_token"
        "x_media_tracker_mcp_token"
        "x_budget_mcp_token"
        "trilium_mcp_token"
        "wikidata_mcp_token"
    ];
    bearer = token: { Authorization = "Bearer ${config.sops.placeholder.${token}}"; };

    # ProfessionalWiki's MediaWiki server, built from the lockfile in ./mediawiki rather than fetched by npx, so it can be patched.
    # Its mwn client sends maxlag=5 on every request, and Wikidata counts its query service's lag (often 10 s or more) against that, so even reads
    # fail for hours at a time. The patch drops maxlag from reads and raises it to 30 s for writes, which are the requests that carry a CSRF token;
    # every write is approved by hand, so they are never the high-volume traffic maxlag exists to slow down.
    mediawikiModules = pkgs.importNpmLock.buildNodeModules {
        npmRoot = ./mediawiki;
        inherit (pkgs) nodejs;
        derivationArgs.postInstall = ''
            substituteInPlace $out/node_modules/@professional-wiki/mediawiki-mcp-server/dist/wikis/mwnProvider.js \
                --replace-fail "const instance = this.createMwn(options);" \
                    "const instance = this.createMwn(options); const request = instance.request.bind(instance); instance.request = (params, opts) => request({ maxlag: params.token ? 30 : undefined, ...params }, opts);"
        '';
    };

    servers = {
        x-nix = {
            url = "https://nix.heimdall.technet/api/mcp";
            headers = bearer "x_nix_mcp_token";
        };
        x-backups = {
            url = "https://backups.heimdall.technet/api/mcp";
            headers = bearer "x_backups_mcp_token";
        };
        x-media-tracker = {
            url = "https://media-tracker.heimdall.technet/api/mcp";
            headers = bearer "x_media_tracker_mcp_token";
        };
        x-budget = {
            url = "https://budget.heimdall.technet/api/mcp";
            headers = bearer "x_budget_mcp_token";
        };
        x-dev.url = "http://127.0.0.1:3921/mcp";
        # Served by Heimdall, so the desktop apps need not be open; X-Tasks has a token of its own, apart from CODEX's
        x-fitness = {
            url = "https://fitness.heimdall.technet/api/mcp";
            headers = bearer "x_fitness_mcp_token";
        };
        X-Tasks = {
            url = "https://tasks.heimdall.technet/api/mcp";
            headers = bearer "x_tasks_mcp_token";
        };
        trilium = {
            url = "http://127.0.0.1:37840/mcp";
            headers.Authorization = config.sops.placeholder.trilium_mcp_token;
        };
        npm = {
            type = "stdio";
            command = "${pkgs.nodejs}/bin/npx";
            args = [
                "-y"
                "@mikusnuz/npm-mcp@1.4.0"
            ];
        };
        # FoxMCP drives the running Firefox through its add-on, installed below. --single-instance makes every session join one shared worker
        # holding the add-on's WebSocket on port 8765, instead of each session fighting for the port. uv's own Python builds do not run on NixOS.
        foxmcp = {
            type = "stdio";
            command = "${pkgs.uv}/bin/uvx";
            args = [
                "--python"
                "${pkgs.python3}/bin/python3"
                "--from"
                "foxmcp==1.7.0"
                "foxmcp"
                "--stdio"
                "--single-instance"
            ];
            env.UV_PYTHON_DOWNLOADS = "never";
        };
        # The MediaWiki server reads its wikis and their tokens from a config file, rendered from sops below.
        mediawiki = {
            type = "stdio";
            command = "${pkgs.nodejs}/bin/node";
            args = [ "${mediawikiModules}/node_modules/@professional-wiki/mediawiki-mcp-server/dist/index.js" ];
            env.CONFIG = config.sops.templates."mediawiki-mcp.json".path;
        };
    };
in
{
    sops.secrets =
        builtins.listToAttrs (
            map (token: {
                name = token;
                value.sopsFile = "${config.technet.secrets.path}/claude-mcp.yaml";
            }) tokens
        )
        // {
            # Saved by scripts/set-codex-api-key.sh beside CODEX's keys; Claude Code's own, not CODEX's
            x_tasks_mcp_token.sopsFile = "${config.technet.secrets.path}/codex.yaml";
        };

    sops.templates."claude-managed-mcp.json" = {
        owner = "beatlink";
        content = builtins.toJSON {
            mcpServers = builtins.mapAttrs (_: server: { type = "http"; } // server) servers;
        };
    };

    sops.templates."mediawiki-mcp.json" = {
        owner = "beatlink";
        content = builtins.toJSON {
            defaultWiki = "www.wikidata.org";
            allowWikiManagement = false;
            wikis."www.wikidata.org" = {
                sitename = "Wikidata";
                server = "https://www.wikidata.org";
                articlepath = "/wiki";
                scriptpath = "/w";
                token = config.sops.placeholder.wikidata_mcp_token;
            };
        };
    };

    # The add-on half of FoxMCP. Firefox updates it from AMO; keep the server pin above on a version whose protocol matches.
    programs.firefox.policies.ExtensionSettings."foxmcp@codemud.org" = {
        installation_mode = "normal_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/foxmcp/latest.xpi";
    };

    # sops-nix makes no parent folders for a template path, so /etc/claude-code comes from here, linked to the rendered file.
    environment.etc."claude-code/managed-mcp.json".source =
        config.sops.templates."claude-managed-mcp.json".path;

    # npm's tools act on the registry with the token in ~/.npmrc, so every call waits for approval; managed rules outrank any user allow.
    environment.etc."claude-code/managed-settings.json".text = builtins.toJSON {
        permissions.ask = [
            "mcp__npm"
        ]
        # MediaWiki's reads run freely, but every tool it does not mark read-only waits, so each wiki edit is approved after reading it.
        ++ map (tool: "mcp__mediawiki__${tool}") [
            "add-wiki"
            "create-page"
            "delete-page"
            "move-page"
            "neowiki-create-subject"
            "neowiki-delete-subject"
            "neowiki-set-main-subject"
            "neowiki-update-subject"
            "oauth-logout"
            "protect-page"
            "remove-wiki"
            "undelete-page"
            "update-file"
            "update-file-from-url"
            "update-page"
            "upload-file"
            "upload-file-from-url"
            "wikibase-add-statement"
            "wikibase-edit-entity"
        ];
    };
    # A symlink makes Claude Code watch /nix/store and balloon to gigabytes on every store change (anthropics/claude-code#98701).
    environment.etc."claude-code/managed-settings.json".mode = "0444";

    environment.systemPackages = [
        (pkgs.writeShellApplication {
            name = "set-mcp-token";
            runtimeInputs = [
                pkgs.git
                pkgs.python3
                pkgs.sops
            ];
            text = ''exec python3 ${./set-mcp-token.py} "$@"'';
        })
    ];
}
