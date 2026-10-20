# SmartHarness #######################################################################################################################################
#
# The staged harness for local GGUF models built in /Storage/Files/Projects/SmartHarness, installed from its GitHub flake with Trilium's MCP tools.
#
{ config, inputs, ... }:
let
    token_path = config.sops.secrets.trilium_etapi_token.path;
in
{
    home-manager.users.beatlink =
        { lib, pkgs, ... }:
        let
            smartharness = inputs.smartharness.packages.${pkgs.stdenv.hostPlatform.system}.default;
            settings = pkgs.writeText "smartharness-settings.json" (
                builtins.toJSON {
                    model_path = "/Storage/Files/Projects/SmartHarness/models/model.gguf";
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
                        name = "smartharness";
                        paths = [ smartharness ];
                        nativeBuildInputs = [ pkgs.makeWrapper ];
                        postBuild = ''
                            for program in smartharness smartharness-tui; do
                                wrapProgram $out/bin/$program --run 'export TRILIUM_ETAPI_TOKEN="$(cat ${token_path})"'
                            done
                        '';
                    })
                ];

                # The settings and the knowledge store live here, and the home rollback would otherwise blank both.
                persistence."/Storage/Apps/AI/SmartHarness" = {
                    directories = [
                        ".config/smartharness"
                        ".local/share/smartharness"
                    ];
                };

                # The options page rewrites this file, so it is seeded once instead of linked read-only from the store.
                activation.smartharnessSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                    [ -e "$HOME/.config/smartharness/settings.json" ] || run install -Dm644 ${settings} "$HOME/.config/smartharness/settings.json"
                '';
            };
        };
}
