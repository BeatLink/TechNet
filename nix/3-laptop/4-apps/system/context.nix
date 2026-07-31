# Context
#
# A context-oriented desktop shell, developed in /Storage/Files/Projects/Coding/Context. Rather than
# managing windows and workspaces directly, work is organised into named contexts — groups of applications
# opened to specific resources — which it instantiates as Hyprland workspaces.
#
# It is not packaged yet, so nothing is installed here; this module only persists its state across reboots.
# The store lives at $XDG_DATA_HOME/context and holds:
#
#   contexts.json       context definitions, including the workspace handle each one owns
#   firefox-profiles/   a Firefox profile per context, for contexts not sharing the main profile
#
# Losing contexts.json would lose every context definition, and losing the profiles would lose the cookies,
# history and tabs belonging to each context, so both are persisted.
#

{
    home-manager.users.beatlink = {
        home.persistence."/Storage/Apps/System/Context" = {
            directories = [
                ".local/share/context"
            ];
        };
    };
}
