# Bookmark Sorter
#
# `bookmark-sorter plan` sorts Firefox's loose bookmarks into a standing set of
# folders with a local model; the extension beside it applies the result.
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
            packages = [ bookmark-sorter ];

            # The extension moves bookmarks through Firefox's own API, so the browser stays open and nothing writes to places.sqlite behind it.
            # Release Firefox installs only signed add-ons, so this is loaded from about:debugging, which lasts until the browser restarts.
            file.".local/share/bookmark-sorter/extension".source = ./bookmark-sorter-extension;

            # The plan is written to the home directory, which persists already; nothing to add here.
        };
    };
}
