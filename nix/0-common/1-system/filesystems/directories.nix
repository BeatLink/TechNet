# Storage Directories ################################################################################################################################
#
# Creates /Storage and the XDG directories under it, which point at the data pool so saved files survive the rollback.
#

{ ... }:
{
    # The tmpfiles rules and the XDG pointers list the same six paths and have to agree, so they are kept together.
    systemd.tmpfiles.settings."Storage" = {
        "/Storage".d = {
            user = "beatlink";
            group = "beatlink";
            mode = "1777";
        };
        "/Storage/Apps".d = {
            user = "root"; # Root-owned because impermanence creates each app's bind-mount source under it itself
            group = "root";
            mode = "0755";
        };
        "/Storage/Files".d = {
            user = "beatlink";
            group = "beatlink";
            mode = "0755";
        };
        "/Storage/Files/Desktop".d = {
            user = "beatlink";
            group = "beatlink";
            mode = "0755";
        };
        "/Storage/Files/Documents".d = {
            user = "beatlink";
            group = "beatlink";
            mode = "0755";
        };
        "/Storage/Files/Downloads".d = {
            user = "beatlink";
            group = "beatlink";
            mode = "0755";
        };
        "/Storage/Files/Music".d = {
            user = "beatlink";
            group = "beatlink";
            mode = "0755";
        };
        "/Storage/Files/Pictures".d = {
            user = "beatlink";
            group = "beatlink";
            mode = "0755";
        };
        "/Storage/Files/Videos".d = {
            user = "beatlink";
            group = "beatlink";
            mode = "0755";
        };
    };

    home-manager.users.beatlink.xdg.userDirs = {
        enable = true;
        desktop = "/Storage/Files/Desktop";
        documents = "/Storage/Files/Documents";
        download = "/Storage/Files/Downloads";
        music = "/Storage/Files/Music";
        pictures = "/Storage/Files/Pictures";
        videos = "/Storage/Files/Videos";
    };
}
