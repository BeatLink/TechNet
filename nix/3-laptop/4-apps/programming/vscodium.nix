{
    home-manager.users.beatlink =
        {
            pkgs,
            ...
        }:
        {
            programs = {
                claude-code.enable = true;
                vscodium = {
                    enable = true;
                    profiles.default = {
                        enableExtensionUpdateCheck = true;
                        extensions = with pkgs.vscode-extensions; [
                            hediet.vscode-drawio
                            anthropic.claude-code
                            signageos.signageos-vscode-sops
                            #editorconfig
                            #error lense
                            # es6-string-html
                            dbaeumer.vscode-eslint
                            grafana.grafana-alloy
                            lokalise.i18n-ally
                            ms-vscode.live-server
                            jnoortheen.nix-ide
                            tyriar.sort-lines
                            #hex.stylint-plus
                            # Todo Tree
                            redhat.vscode-yaml
                            #markdown all in one
                            # office viewer
                            # Playwright test for vscode
                            #vitest.vitest-explorer
                            #vscode-pdf

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

/**

/home/beatlink/.vscode-oss/extensions/cweijan.vscode-office-4.0.4-universal /home/beatlink/.vscode-oss/extensions/dbaeumer.vscode-eslint /home/beatlink/.vscode-oss/extensions/dbaeumer.vscode-eslint-3.0.24-universal /home/beatlink/.vscode-oss/extensions/editorconfig.editorconfig-0.18.2-universal /home/beatlink/.vscode-oss/extensions/grafana.grafana-alloy /home/beatlink/.vscode-oss/extensions/grafana.grafana-alloy-0.2.0-universal /home/beatlink/.vscode-oss/extensions/gruntfuggly.todo-tree-0.0.215 /home/beatlink/.vscode-oss/extensions/hediet.vscode-drawio /home/beatlink/.vscode-oss/extensions/hex-ci.stylelint-plus-2.2.2-universal /home/beatlink/.vscode-oss/extensions/jnoortheen.nix-ide /home/beatlink/.vscode-oss/extensions/jnoortheen.nix-ide-0.5.9-universal /home/beatlink/.vscode-oss/extensions/lokalise.i18n-ally-2.13.1-universal /home/beatlink/.vscode-oss/extensions/Lokalise.i18n-ally /home/beatlink/.vscode-oss/extensions/ms-playwright.playwright-1.1.19-universal /home/beatlink/.vscode-oss/extensions/ms-vscode.live-server /home/beatlink/.vscode-oss/extensions/redhat.vscode-yaml /home/beatlink/.vscode-oss/extensions/redhat.vscode-yaml-1.23.0-universal /home/beatlink/.vscode-oss/extensions/signageos.signageos-vscode-sops /home/beatlink/.vscode-oss/extensions/tobermory.es6-string-html-2.14.1-universal /home/beatlink/.vscode-oss/extensions/tyriar.sort-lines-1.12.0-universal /home/beatlink/.vscode-oss/extensions/Tyriar.sort-lines /home/beatlink/.vscode-oss/extensions/usernamehw.errorlens-3.28.0-universal /home/beatlink/.vscode-oss/extensions/vitest.explorer-1.50.6-universal /home/beatlink/.vscode-oss/extensions/yzhang.markdown-all-in-one-3.6.2-universal 
*/