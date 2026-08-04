# Nemo
#
# Settings are stored in dconf and exported into this folder by
# `nixtool run maintenance/export-dconf`.
#
# Two things genuinely differ between a laptop and a phone, so both are options
# rather than shared literals:
#
#   extraPackages  Odin pulls nemo-preview, ffmpeg-full and imagemagick for
#                  thumbnailing. That is a lot of closure for a phone on an SD
#                  card, so Thor takes the default of none.
#
#   bookmarks      Odin's list names ten /Storage/Files subdirectories that
#                  exist on the laptop. Most of those are empty or absent on the
#                  phone, and a bookmark to a missing directory is worse than no
#                  bookmark. It is a single file, so it cannot be merged from
#                  two modules -- hence one option rather than a shared base
#                  plus per-host additions.
#
{
    config,
    lib,
    pkgs,
    ...
}:
let
    cfg = config.technet.desktop.nemo;
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
            default = ''
                file:///Storage Storage
                file:///Storage/Files Files
            '';
            description = ''
                Contents of ~/.config/gtk-3.0/bookmarks, the standard GTK
                bookmarks file Nemo reads.

                Portfolio cannot use this -- its places list is hardcoded and
                comes from the XDG user directories instead, which
                1-home-folders.nix points at /Storage/Files.
            '';
        };
    };

    config = {
        programs.fuse.userAllowOther = true;

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
