{
    home-manager.users.beatlink =
        {
            pkgs,
            lib,
            inputs,
            ...
        }:
        {
            nixpkgs = {
                overlays = [ inputs.nix-vscode-extensions.overlays.default ];
                config.allowUnfreePredicate = pkg: lib.hasPrefix "vscode-extension-" (lib.getName pkg);
            };

            programs = {
                claude-code.enable = true;
                vscodium = {
                    enable = true;
                    mutableExtensionsDir = false;
                    profiles.default = {
                        enableExtensionUpdateCheck = true;
                        extensions = with pkgs.nix-vscode-extensions.open-vsx; [
                            hediet.vscode-drawio
                            anthropic.claude-code
                            signageos.signageos-vscode-sops
                            editorconfig.editorconfig
                            usernamehw.errorlens
                            tobermory.es6-string-html
                            dbaeumer.vscode-eslint
                            grafana.grafana-alloy
                            lokalise.i18n-ally
                            ms-vscode.live-server
                            jnoortheen.nix-ide
                            tyriar.sort-lines
                            hex-ci.stylelint-plus
                            gruntfuggly.todo-tree
                            redhat.vscode-yaml
                            yzhang.markdown-all-in-one
                            cweijan.vscode-office
                            ms-playwright.playwright
                            vitest.explorer
                            tomoki1207.pdf
                        ];
                    };
                };
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
