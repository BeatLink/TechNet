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
        "trilium_mcp_token"
        "trilium_sysadmin_mcp_token"
        "wikidata_mcp_token"
    ];
    bearer = token: { Authorization = "Bearer ${config.sops.placeholder.${token}}"; };
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
        x-fitness.url = "http://127.0.0.1:3918/mcp";
        X-Tasks.url = "http://127.0.0.1:3917/mcp";
        trilium = {
            url = "http://127.0.0.1:37840/mcp";
            headers.Authorization = config.sops.placeholder.trilium_mcp_token;
        };
        trilium-sysadmin = {
            url = "http://127.0.0.1:12351/mcp";
            headers.Authorization = config.sops.placeholder.trilium_sysadmin_mcp_token;
        };
        npm = {
            type = "stdio";
            command = "${pkgs.nodejs}/bin/npx";
            args = [
                "-y"
                "@mikusnuz/npm-mcp@1.4.0"
            ];
        };
        # ProfessionalWiki's MediaWiki server reads its wikis and their tokens from a config file, rendered from sops below.
        mediawiki = {
            type = "stdio";
            command = "${pkgs.nodejs}/bin/npx";
            args = [
                "-y"
                "@professional-wiki/mediawiki-mcp-server@0.21.0"
            ];
            env.CONFIG = config.sops.templates."mediawiki-mcp.json".path;
        };
    };
in
{
    sops.secrets = builtins.listToAttrs (
        map (token: {
            name = token;
            value.sopsFile = "${config.technet.secrets.path}/claude-mcp.yaml";
        }) tokens
    );

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
