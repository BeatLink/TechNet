# Command Not Found ##################################################################################################################################
#
# Off because the handler indexes the channel's programs.sqlite, which a flake-only system never populates, making every miss an error instead of a hint.
#

{ ... }:
{
    programs.command-not-found.enable = false;

    home-manager.users.beatlink = {
        programs.command-not-found.enable = false;
    };
}
