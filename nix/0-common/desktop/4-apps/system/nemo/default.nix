# Nemo
#
# Settings are stored in dconf and exported into this folder by
# `nixtool run maintenance/export-dconf`.
#
# Two things differ between a laptop and a phone, and both are additive options
# rather than shared literals a host would have to restate:
#
#   extraPackages  Odin pulls nemo-preview, ffmpeg-full and imagemagick for
#                  thumbnailing. That is a lot of closure for a phone on an SD
#                  card, so Thor takes the default of none.
#
#   bookmarks      Odin has Projects, VMs and Backups; the phone does not, and a
#                  bookmark to a directory that does not exist is worse than no
#                  bookmark. types.lines merges definitions by joining them with
#                  newlines, so Odin names only its three and the shared set
#                  below supplies the rest.
#
{
    config,
    lib,
    pkgs,
    ...
}:
let
    cfg = config.technet.desktop.nemo;

    # Every host but this one. Nemo would happily bookmark an sftp path back to
    # the machine it is running on, and it would even work, but it is noise.
    remoteStorage = lib.concatMapStringsSep "\n" (host:
        "sftp://beatlink@${lib.toLower host}.technet/Storage ${host}"
    ) (lib.filter (host: host != config.networking.hostName) [
        "Heimdall"
        "Ragnarok"
        "Thor"
    ]);
in
{
    options.technet.desktop.nemo = {
        extraPackages = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [ ];
            description = ''
                Helper packages installed alongside Nemo, for thumbnailing and
                preview. Empty by default so a small host pays nothing for them.
            '';
        };

        bookmarks = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = ''
                Contents of ~/.config/gtk-3.0/bookmarks, the standard GTK
                bookmarks file Nemo reads.

                types.lines merges definitions by joining them with newlines, so
                a host adds its own by simply setting this again -- no separate
                "extra" option, and no restating the shared set. The shared list
                is a definition below rather than a default here, because
                defaults are replaced by a definition rather than merged with
                it.

                mkBefore/mkAfter pin the sequence: merge order otherwise follows module
                import order, which is not something to rely on when the value
                is a visible list in a sidebar. The shared entries come first,
                host ones after.

                Portfolio cannot use this -- its places list is hardcoded and
                comes from the XDG user directories instead, which
                1-home-folders.nix points at /Storage/Files.
            '';
        };
    };

    config = {
        programs.fuse.userAllowOther = true;

        # Everything that exists on every desktop host. Projects, VMs and
        # Backups are deliberately absent: they are Odin's, and a bookmark to a
        # directory that does not exist is worse than no bookmark.
        technet.desktop.nemo.bookmarks = lib.mkBefore ''
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
            home = {
                packages = [ pkgs.nemo-with-extensions ] ++ cfg.extraPackages;

                persistence."/Storage/Apps/System/Nemo" = {
                    directories = [
                        ".config/nemo"
                        ".local/share/nemo"
                    ];

                };

                file = {
                    ".config/gtk-3.0/bookmarks".text = cfg.bookmarks;
                };
            };
        };
    };
}
