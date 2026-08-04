# Storage folders
#
# The two top-level directories every desktop host's data pool is organised
# around, plus the XDG directories 1-home-folders.nix points at.
#
# These were previously created by hand. Odin has had them since July and
# nothing in the repo declared them, so a rebuilt host -- or Thor, whose card
# was reformatted from empty -- would come up with xdg.userDirs pointing at
# directories that do not exist. GTK then silently falls back to $HOME, which
# looks like the setting being ignored rather than a missing directory.
#
# Ownership matches what Odin grew into: /Storage/Apps is root's, because it
# only ever holds impermanence bind-mount sources and impermanence creates each
# app's directory under it itself; /Storage/Files is beatlink's, because that is
# where the user's own data goes.
#
# Servers get none of this. Ragnarok's /Storage/Backups is declared next to borg
# in 1-backup-server, which is the right place for it.
#
{
    systemd.tmpfiles.settings."Storage-Folders" = {
        "/Storage/Apps".d = {
            user = "root";
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
}
