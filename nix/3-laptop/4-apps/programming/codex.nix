# CODEX ##############################################################################################################################################
#
# The staged harness for local GGUF models built in /Storage/Files/Projects/CODEX, installed from its GitHub flake with Trilium's MCP tools.
#
{ config, inputs, ... }:
let
    token_path = config.sops.secrets.trilium_etapi_token.path;
in
{
    home-manager.users.beatlink =
        { lib, pkgs, ... }:
        let
            codex = inputs.codex.packages.${pkgs.stdenv.hostPlatform.system}.default;
            settings = pkgs.writeText "codex-settings.json" (
                builtins.toJSON {
                    model_path = "/Storage/Files/Projects/CODEX/models/model.gguf";
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
                packages = [
                    (pkgs.symlinkJoin {
                        name = "codex";
                        paths = [ codex ];
                        nativeBuildInputs = [ pkgs.makeWrapper ];
                        postBuild = ''
                            for program in $out/bin/*; do
                                wrapProgram $program --run 'export TRILIUM_ETAPI_TOKEN="$(cat ${token_path})"'
                            done
                        '';
                    })
                ];

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
        };
}
