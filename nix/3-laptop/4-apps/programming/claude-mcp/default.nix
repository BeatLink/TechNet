# Claude MCP #########################################################################################################################################
#
# The API tokens Claude Code sends to the X-apps' MCP endpoints, and the tools that set them and hand them over.
#
# set-mcp-token stores a token pasted from an app's Your account page in sops and registers the app with Claude Code; mcp-token-header is the
# headers helper Claude Code runs on each connect, so a token is only read from /run/secrets and never sits in Claude's config.
#
{ config, pkgs, ... }:
{
    # X-Fitness's token is declared beside the app, in core/x-fitness.nix.
    sops.secrets = {
        x_nix_mcp_token = {
            sopsFile = "${config.technet.secrets.path}/claude-mcp.yaml";
            owner = "beatlink";
        };
        x_backups_mcp_token = {
            sopsFile = "${config.technet.secrets.path}/claude-mcp.yaml";
            owner = "beatlink";
        };
    };

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
        (pkgs.writeShellApplication {
            name = "mcp-token-header";
            runtimeInputs = [ pkgs.jq ];
            text = ''jq -cn --rawfile token "/run/secrets/$1" '{Authorization: ("Bearer " + ($token | rtrimstr("\n")))}' '';
        })
    ];
}
