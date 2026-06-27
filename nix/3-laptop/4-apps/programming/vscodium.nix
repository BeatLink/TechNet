{
    home-manager.users.beatlink =
        { pkgs, lib, ... }:
        {
            programs.vscodium = {
                enable = true;
                package = pkgs.vscodium;
                extensions = [
                    pkgs.vscode-extensions.signageos.signageos-vscode-sops
                    pkgs.vscode-extensions.hediet.vscode-drawio
                    pkgs.vscode-extensions.anthropic.claude-code
                ];
                profiles.default = {};
            };

            home = {
                packages = with pkgs; [
                    nixd
                    nixfmt
                    nil
                ];
                persistence."/Storage/Apps/Programming/VsCodium" = {
                    directories = [
                        ".config/VSCodium"
                        ".local/share/codium"
                        ".vscode-oss"
                    ];
                    files = [ ".config/npmrc" ];

                };
            };
        };
}
