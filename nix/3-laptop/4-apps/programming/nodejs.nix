{ pkgs, ... }:
{
    # Provides `node` and `npx`. MCP servers are distributed as npm packages that
    # Claude launches with `npx <package>`, so the CLI has to be on PATH.
    environment.systemPackages = with pkgs; [
        nodejs
    ];
}
