{ inputs, ... }:
{
    # home-manager.useGlobalPkgs is enabled in nix/0-common/2-users, so the extension overlay is applied to the
    # system package set rather than a per-user one. allowUnfree is already set globally in
    # nix/0-common/1-system/5-software/4-unfree-packages.nix, which covers the unfree extensions here.
    nixpkgs.overlays = [ inputs.nix-vscode-extensions.overlays.default ];

    home-manager.users.beatlink =
        {
            config,
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
                        # settings.json is a symlink into the store, so nothing set
                        # from the settings UI survives -- everything wanted has to
                        # be here. What follows was reconciled against
                        # settings.json.hmbackup, the mutable file home-manager
                        # displaced when it took the path over.
                        userSettings = {
                            # Appearance -----------------------------------------------------------------------------------------------------
                            # With autoDetectColorScheme on, workbench.colorTheme
                            # is ignored entirely -- the preferred* pair is what
                            # applies, picked by the system light/dark preference.
                            # colorTheme stays declared as the fallback for when
                            # auto-detection is turned off.
                            "window.autoDetectColorScheme" = true;
                            "workbench.preferredLightColorTheme" = "Light 2026";
                            "workbench.preferredDarkColorTheme" = "Dark 2026";
                            "workbench.colorTheme" = "Light 2026";
                            "workbench.iconTheme" = "material-icon-theme";
                            "workbench.tree.indent" = 20;
                            "workbench.enableExperiments" = false;
                            "workbench.editor.enablePreview" = false;
                            "workbench.editorAssociations" = {
                                "*.nix" = "default";
                                "*.svg" = "default";
                            };
                            "workbench.settings.applyToAllProfiles" = [ "git.requireGitUserConfig" ];
                            "window.newWindowProfile" = "Default";
                            "editor.minimap.enabled" = false;

                            # Files and explorer ---------------------------------------------------------------------------------------------
                            "files.autoSave" = "afterDelay";
                            "files.autoSaveDelay" = 1000;
                            "files.exclude" = {
                                "**/__pycache__" = true;
                                "**/*.pyc" = true;
                                "**/*.pyo" = true;
                            };
                            "files.watcherExclude" = {
                                "**/.direnv/**" = true;
                                "**/result" = true;
                                "**/flake.lock" = true;
                            };
                            "explorer.confirmDelete" = false;
                            "explorer.confirmDragAndDrop" = false;
                            "explorer.compactFolders" = false;
                            "explorer.sortOrder" = "filesFirst";

                            # Editor ---------------------------------------------------------------------------------------------------------
                            "editor.formatOnSave" = true;
                            "diffEditor.ignoreTrimWhitespace" = false;
                            "diffEditor.codeLens" = true;
                            "emmet.includeLanguages" = {
                                "javascript" = "javascriptreact";
                            };
                            "http.systemCertificatesNode" = true;

                            # Terminal -------------------------------------------------------------------------------------------------------
                            # Only bash is declared; the zsh/fish/tmux/pwsh entries
                            # the old file carried named shells this machine does
                            # not install.
                            "terminal.integrated.defaultProfile.linux" = "bash";
                            "terminal.integrated.profiles.linux" = {
                                bash = {
                                    path = "bash";
                                    icon = "terminal-bash";
                                    args = [ ];
                                    env = {
                                        TERM = "xterm-256color";
                                    };
                                };
                            };
                            "terminal.integrated.initialHint" = false;

                            # Git ------------------------------------------------------------------------------------------------------------
                            "git.path" = "${pkgs.git}/bin/git";
                            "git.enableSmartCommit" = true;
                            "git.confirmSync" = false;
                            "git.autofetch" = true;
                            "git.showPushSuccessNotification" = true;
                            "git.requireGitUserConfig" = false;
                            "git.terminalAuthentication" = false;
                            "git.useEditorAsCommitInput" = false;
                            "git.replaceTagsWhenPull" = true;
                            "github.gitProtocol" = "ssh";

                            # Languages ------------------------------------------------------------------------------------------------------
                            "[python]" = {
                                "editor.defaultFormatter" = "ms-python.black-formatter";
                                "editor.formatOnSave" = true;
                                "diffEditor.ignoreTrimWhitespace" = false;
                            };
                            "[nix]" = {
                                "editor.tabSize" = 4;
                            };
                            "[dockercompose]" = {
                                "editor.insertSpaces" = true;
                                "editor.tabSize" = 2;
                                "editor.autoIndent" = "advanced";
                                "editor.defaultFormatter" = "redhat.vscode-yaml";
                            };
                            "[github-actions-workflow]" = {
                                "editor.defaultFormatter" = "redhat.vscode-yaml";
                            };
                            "javascript.format.semicolons" = "remove";
                            "javascript.preferences.quoteStyle" = "double";
                            "javascript.updateImportsOnFileMove.enabled" = "always";
                            "typescript.updateImportsOnFileMove.enabled" = "always";

                            # Python formatting ----------------------------------------------------------------------------------------------
                            "black-formatter.path" = [ "${pkgs.black}/bin/black" ];
                            "black-formatter.showNotifications" = "always";
                            "black-formatter.interpreter" = [ "${pkgs.python3}/bin/python3" ];

                            # Nix language server --------------------------------------------------------------------------------------------
                            # The old file pointed at ~/.nix-profile, which is not
                            # what installs these -- they come from home.packages
                            # below, so name the store paths directly.
                            "nix.enableLanguageServer" = true;
                            "nix.serverPath" = "${pkgs.nixd}/bin/nixd";
                            "nix.serverSettings" = {
                                nixd.formatting.command = [
                                    "${pkgs.nixfmt}/bin/nixfmt"
                                    "--indent"
                                    "4"
                                ];
                            };
                            "nix.showUnstableFeatures" = true;

                            # sops -----------------------------------------------------------------------------------------------------------
                            "sops.defaults.ageKeyFile" = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
                            "sops.creationEnabled" = true;

                            # todo-tree ------------------------------------------------------------------------------------------------------
                            "todo-tree.tree.showScanModeButton" = false;
                            "todo-tree.general.tags" = [
                                "BUG"
                                "HACK"
                                "FIXME"
                                "TODO"
                                "XXX"
                                "[ ]"
                                "[x]"
                            ];
                            "todo-tree.regex.regex" = "(//|#|<!--|;|/\\*|^|^\\s*(-|\\d+.))\\s*($TAGS)";

                            # Other extensions -----------------------------------------------------------------------------------------------
                            "claudeCode.preferredLocation" = "panel";
                            "chat.extensionUnification.enabled" = false;
                            "liveServer.settings.donotShowInfoMsg" = true;
                            "vscode-office.openOutline" = true;
                            "redhat.telemetry.enabled" = true;
                            # Extensions come from the store and mutableExtensionsDir
                            # is off, so there is nothing for an auto-update to do.
                            # As of 1.125 this is a string enum ("on"/"off"), not a
                            # boolean -- `false` fails validation and silently falls
                            # back to the "on" default.
                            "extensions.autoUpdate" = "off";
                        };
                        extensions = with pkgs.nix-vscode-extensions.open-vsx; [
                            hediet.vscode-drawio
                            anthropic.claude-code
                            pkief.material-icon-theme
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
