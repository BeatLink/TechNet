# VSCodium
#
# The editor's own configuration lives in nix/0-common/4-apps/tools/vscodium.nix, shared with the instance Heimdall runs for Thor. What is here is
# what belongs to this machine alone: Claude Code, the toolchains the settings point at, and the state to persist.
#
{ ... }:
{
    technet.vscodium.enable = true;

    home-manager.users.beatlink =
        {
            config,
            pkgs,
            ...
        }:
        {
            programs.claude-code.enable = true;

            home = {
                # Claude Code's temp root, inside the persisted .claude below rather than on /tmp, so scratchpads and task output outlive a reboot along with the rest of its state
                sessionVariables.CLAUDE_CODE_TMPDIR = "${config.home.homeDirectory}/.claude/tmp";

                # Claude Code's config home, so .claude.json lands inside the persisted .claude instead of at the home root the rollback blanks
                sessionVariables.CLAUDE_CONFIG_DIR = "${config.home.homeDirectory}/.claude";

                packages = with pkgs; [
                    nixd
                    nixfmt
                    nil
                    vala
                    vala-language-server
                    vala-lint
                    meson
                    ninja
                    pkg-config
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
