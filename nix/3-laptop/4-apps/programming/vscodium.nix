{ inputs, ... }:
{
    # home-manager.useGlobalPkgs is enabled in nix/0-common/2-users, so the extension overlay is applied to the
    # system package set rather than a per-user one. allowUnfree is already set globally in
    # nix/0-common/1-system/5-software/4-unfree-packages.nix, which covers the unfree extensions here.
    nixpkgs.overlays = [ inputs.nix-vscode-extensions.overlays.default ];

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
                    mutableExtensionsDir = false;
                    profiles.default = {
                        enableExtensionUpdateCheck = true;
                        userSettings = {
                            "workbench.colorTheme" = "Light 2026";
                            "files.autoSave" = "afterDelay";
                            "files.autoSaveDelay" = 1000;
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
