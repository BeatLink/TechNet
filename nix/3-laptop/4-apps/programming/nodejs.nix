{ pkgs, ... }:
{
    # Provides `node` and `npx`. MCP servers are distributed as npm packages that
    # Claude launches with `npx <package>`, so the CLI has to be on PATH.
    environment.systemPackages = with pkgs; [
        nodejs
    ];

    home-manager.users.beatlink = {
        home = {
            persistence."/Storage/Apps/Programming/NodeJS" = {
                files = [
                    ".npmrc" # registry auth tokens and npm CLI settings
                ];
            };
        };
    };
}
