{ pkgs, ... }:
{
    # Provides `node` and `npx`. MCP servers are distributed as npm packages that
    # Claude launches with `npx <package>`, so the CLI has to be on PATH.
    environment.systemPackages = with pkgs; [
        nodejs
    ];

    home-manager.users.beatlink =
        { config, ... }:
        {
            home = {
                sessionVariables = {
                    NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
                    npm_config_cache = "${config.xdg.cacheHome}/npm";
                };
                persistence."/Storage/Apps/Programming/NodeJS" = {
                    files = [
                        ".config/npm/npmrc" # registry auth tokens and npm CLI settings
                    ];
                };
            };
        };
}
