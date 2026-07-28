{ pkgs, ... }:
{
    environment.systemPackages = with pkgs; [
        gh
    ];

    home-manager.users.beatlink = {
        home = {
            persistence."/Storage/Apps/Programming/GitHubCLI" = {
                directories = [
                    ".config/gh" # OAuth token, host and CLI settings
                ];
            };
        };
    };
}
