# Bookmark Sorter
#
# Files Firefox's loose bookmarks into folders a local LLM proposes, in two
# steps: `bookmark-sorter plan` writes a plan, `apply` carries it out.
#
{ config, pkgs, ... }:
let
    unwrapped = pkgs.writers.writePython3Bin "bookmark-sorter" {
        libraries = [ ];
        flakeIgnore = [
            "E501" # The repo's line length, not flake8's 79
            "W503"
        ];
    } (builtins.readFile ./bookmark-sorter.py);

    # The folder list is the one thing here worth keeping out of a public repo, so it is a secret and the path reaches the tool through its wrapper.
    bookmark-sorter = pkgs.symlinkJoin {
        name = "bookmark-sorter";
        paths = [ unwrapped ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
            wrapProgram $out/bin/bookmark-sorter \
                --set-default BOOKMARK_FOLDERS_FILE ${config.sops.secrets.bookmark_folders.path}
        '';
    };
in
{
    sops.secrets.bookmark_folders = {
        key = "folders";
        sopsFile = "${config.technet.secrets.path}/bookmark-sorter.yaml";
        owner = "beatlink";
    };

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
