# CODEX ##############################################################################################################################################
#
# The staged harness for local GGUF models built in /Storage/Files/Projects/X-Tech-Laboratories/CODEX, installed from that folder's flake with Trilium's MCP tools.
#
{ config, inputs, ... }:
let
    source = "/Storage/Files/Projects/X-Tech-Laboratories/CODEX";
    token_path = config.sops.secrets.trilium_etapi_token.path;
in
{
    home-manager.users.beatlink =
        { lib, pkgs, ... }:
        let
            codex = inputs.codex.packages.${pkgs.stdenv.hostPlatform.system}.default;
            # Wrapped so every program, the daemon included, finds the Trilium token.
            wrapped = pkgs.symlinkJoin {
                name = "codex";
                paths = [ codex ];
                nativeBuildInputs = [ pkgs.makeWrapper ];
                postBuild = ''
                    for program in $out/bin/*; do
                        wrapProgram $program --run 'export TRILIUM_ETAPI_TOKEN="$(cat ${token_path})"'
                    done
                '';
            };
            settings = pkgs.writeText "codex-settings.json" (
                builtins.toJSON {
                    model_path = "/Storage/Files/Projects/X-Tech-Laboratories/CODEX/models/model.gguf";
                    embedding_model_path = "/Storage/Files/Projects/X-Tech-Laboratories/CODEX/models/embedding.gguf";
                    mcp_servers = [
                        {
                            name = "trilium";
                            transport = "http";
                            url = "http://127.0.0.1:37840/mcp";
                            headers.Authorization = "Bearer ${"$"}{TRILIUM_ETAPI_TOKEN}";
                            allowed_tools = [
                                "search_notes"
                                "get_note"
                                "get_note_content"
                                "get_child_notes"
                                "get_subtree"
                                "get_attributes"
                            ];
                        }
                    ];
                }
            );
        in
        {
            home = {
                packages = [ wrapped ];

                # The settings and the knowledge store live here, and the home rollback would otherwise blank both.
                persistence."/Storage/Apps/AI/CODEX" = {
                    directories = [
                        ".config/codex"
                        ".local/share/codex"
                    ];
                };

                # The options page rewrites this file, so it is seeded once instead of linked read-only from the store.
                activation.codexSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                    [ -e "$HOME/.config/codex/settings.json" ] || run install -Dm644 ${settings} "$HOME/.config/codex/settings.json"
                '';
            };

            # Started at login so the model stays loaded and background research runs; the interfaces connect to it over its socket.
            # It runs from the live folder instead of the store copy, so a restart picks up whatever was edited. Untracked files are not seen: git add them.
            systemd.user.services.codex-daemon = {
                Unit.Description = "CODEX daemon";
                Service = {
                    ExecStart = pkgs.writeShellScript "codex-daemon-start" ''
                        export TRILIUM_ETAPI_TOKEN="$(cat ${token_path})"
                        exec ${pkgs.nix}/bin/nix shell git+file://${source}#codex --command codex-daemon
                    '';
                    Restart = "on-failure";
                    RestartSec = 5;
                    TimeoutStartSec = 900; # the first start after an edit rebuilds the package
                };
                Install.WantedBy = [ "default.target" ];
            };

            # Restarts the daemon once the source has been quiet for a minute, so finished work goes live without interrupting an edit in progress.
            systemd.user.services.codex-daemon-watch = {
                Unit.Description = "Restart the CODEX daemon when its source changes";
                Service = {
                    ExecStart = pkgs.writeShellScript "codex-daemon-watch" ''
                        watch() {
                            ${pkgs.inotify-tools}/bin/inotifywait -r -q "$@" -e close_write,create,delete,move \
                                ${source}/src ${source}/package.json ${source}/package-lock.json ${source}/flake.nix ${source}/flake.lock
                        }
                        while watch; do
                            while watch -t 60; do :; done
                            ${pkgs.systemd}/bin/systemctl --user restart codex-daemon
                        done
                    '';
                    Restart = "always";
                };
                Install.WantedBy = [ "default.target" ];
            };
        };
}
