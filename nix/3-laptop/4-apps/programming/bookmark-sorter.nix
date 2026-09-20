# Bookmark Sorter
#
# Files Firefox's loose bookmarks into folders a local LLM proposes, in two
# steps: `bookmark-sorter plan` writes a plan, `apply` carries it out.
#
{ pkgs, ... }:
let
    bookmark-sorter = pkgs.writers.writePython3Bin "bookmark-sorter" {
        libraries = [ ];
        flakeIgnore = [
            "E501" # The repo's line length, not flake8's 79
            "W503"
        ];
    } (builtins.readFile ./bookmark-sorter.py);
in
{
    home-manager.users.beatlink = {
        home = {
            packages = [
                bookmark-sorter
                pkgs.procps # pgrep, which the apply step uses to refuse to run while Firefox is open
            ];

            # The plan is written to the home directory and the profile backups to state, both of which persist already; nothing to add here.
        };
    };
}
