# Claude Chat Manager ################################################################################################################################
#
# Lists the Claude Code transcripts under ~/.claude/projects by project, summarizes one through the claude CLI, and deletes the ones that are done
# with. Ships a terminal interface (claude-chat-manager, or ccm), a GTK window (claude-chat-manager-gtk) and a local web interface (ccm web).
#
{ inputs, ... }:
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = [
                    inputs.claude-chat-manager.packages.${pkgs.stdenv.hostPlatform.system}.default
                ];

                # The summaries and the trash of deleted conversations live here, and the home rollback would otherwise blank both.
                persistence."/Storage/Apps/Programming/ClaudeChatManager" = {
                    directories = [
                        ".config/claude-chat-manager"
                        ".local/share/claude-chat-manager"
                    ];
                };
            };
        };
}
