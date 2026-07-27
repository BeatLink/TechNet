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
                        userSettings = {
                            "workbench.colorTheme" = "Light 2026";
                            "workbench.tree.indent" = 20;
                            "files.exclude" = {
                                "**/__pycache__" = true;
                                "**/*.pyc" = true;
                                "**/*.pyo" = true;
                            };
                            "black-formatter.path" = [ "${pkgs.black}/bin/black" ];
                            "black-formatter.showNotifications" = "always";
                            "black-formatter.interpreter" = [ "${pkgs.python3}/bin/python3" ];
                            "[python]" = {
                                "editor.defaultFormatter" = "ms-python.black-formatter";
                                "editor.formatOnSave" = true;
                            };
                            "git.enableSmartCommit" = true;
                            "git.confirmSync" = false;
                            "claudeCode.preferredLocation" = "panel";
                        };
                        extensions = with pkgs.nix-vscode-extensions.open-vsx; [
                            hediet.vscode-drawio
                            anthropic.claude-code
                            ms-python.python
                            ms-python.black-formatter
                            brainytech.pycacheclear
                            signageos.signageos-vscode-sops
                            editorconfig.editorconfig
                            usernamehw.errorlens
                            tobermory.es6-string-html
                            dbaeumer.vscode-eslint
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
                    python3
                    black
                    (poetry.overridePythonAttrs (old: {
                        doCheck = false;
                    }))
                ];
                persistence."/Storage/Apps/Programming/VsCodium" = {
                    directories = [
                        ".config/VSCodium"
                        ".local/share/codium"
                        ".vscode-oss"
                        ".vscode-oss-shared"
                        ".claude"
                    ];
                    files = [ ".config/npmrc" ];
                };
            };
        };
}
