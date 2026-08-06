# File manager bookmarks, shared between hosts.
#
# Both hosts run Nemo -- see 3-laptop/4-apps/system/nemo and
# 5-phone/3-apps/system/nemo for why. What they have in common is the sidebar:
# it reads ~/.config/gtk-3.0/bookmarks, the standard GTK bookmarks file, so the
# list of places lives here and neither host restates it.
#
# The path outlives any one file manager. gtk-3.0/ is the freedesktop-era
# location rather than a per-toolkit-version one, which is why Nautilus kept
# reading it after going GTK4 in 43, back when Thor ran it.
#
# Only the bookmarks are shared. The packages, the persisted state and the dconf
# exports are per-host, because the two programs agree on nothing else.
{
    config,
    lib,
    ...
}:
let
    cfg = config.technet.desktop.fileManager;

    # Every host but this one. A file manager would happily bookmark an sftp
    # path back to the machine it is running on, and it would even work, but it
    # is noise.
    remoteStorage = lib.concatMapStringsSep "\n" (host:
        "sftp://beatlink@${lib.toLower host}.technet/Storage ${host}"
    ) (lib.filter (host: host != config.networking.hostName) [
        "Odin"
        "Heimdall"
        "Ragnarok"
        "Thor"
    ]);
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
                a host adds its own by simply setting this again -- no separate
                "extra" option, and no restating the shared set. The shared list
                is a definition below rather than a default here, because
                defaults are replaced by a definition rather than merged with
                it.

                mkBefore/mkAfter pin the sequence: merge order otherwise follows
                module import order, which is not something to rely on when the
                value is a visible list in a sidebar. The shared entries come
                first, host ones after.
            '';
        };
    };

    config = {
        programs.fuse.userAllowOther = true;

        # Everything that exists on every desktop host. Projects, VMs and
        # Backups are deliberately absent: they are Odin's, and a bookmark to a
        # directory that does not exist is worse than no bookmark.
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
            home.file.".config/gtk-3.0/bookmarks".text = cfg.bookmarks;
        };
    };
}
