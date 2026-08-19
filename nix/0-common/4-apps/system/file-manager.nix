# File Manager #######################################################################################################################################
#
# The shared sidebar bookmarks, written to ~/.config/gtk-3.0/bookmarks, which every GTK file manager reads.
#

{
    config,
    lib,
    ...
}:
let
    cfg = config.technet.desktop.fileManager;

    remoteStorage =
        lib.concatMapStringsSep "\n"
            (host: "sftp://beatlink@${lib.toLower host}.technet/Storage ${host}")
            (
                lib.filter (host: host != config.networking.hostName) [
                    "Odin"
                    "Heimdall"
                    "Ragnarok"
                    "Thor"
                ]
            );
in
{
    options.technet.desktop.fileManager = {
        bookmarks = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = ''
                Contents of ~/.config/gtk-3.0/bookmarks, the standard GTK
                bookmarks file every GTK file manager reads.

                types.lines merges definitions by joining them with newlines, so
                a host adds its own by simply setting this again. The shared list
                is a definition below rather than a default here, because
                defaults are replaced by a definition rather than merged with it.

                mkBefore/mkAfter pin the sequence, which otherwise follows module
                import order: shared entries first, host ones after.
            '';
        };
    };

    config = {
        programs.fuse.userAllowOther = true;

        # Odin's Projects, VMs and Backups are absent because they are sidebar mounts instead, set up in 3-laptop/1-system/directories.nix
        technet.desktop.fileManager.bookmarks = lib.mkBefore ''
            file:///Storage/Files/Documents Documents
            file:///Storage/Files/Downloads Downloads
            file:///Storage/Files/eBooks eBooks
            file:///Storage/Files/Games Games
            file:///Storage/Files/Music Music
            file:///Storage/Files/Pictures Pictures
            file:///Storage/Files/Sounds Sounds
            file:///Storage/Files/Videos Videos
            file:///Storage Storage
            ${remoteStorage}
        '';

        home-manager.users.beatlink = {
            # nemo-desktop rewrites the file at every login, replacing the symlink, and the backup it earns collides on the next switch
            home.file.".config/gtk-3.0/bookmarks" = {
                text = cfg.bookmarks;
                force = true;
            };
        };
    };
}
