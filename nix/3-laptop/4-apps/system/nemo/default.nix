# Nemo
#
# Odin's file manager. Nemo is Cinnamon's, built for a mouse and a wide window,
# and this is a machine that has both. Thor also runs it now
# (5-phone/3-apps/native/nemo.nix), having gone to Nautilus and back when GTK4
# turned out to render in software on a Mali-400.
#
# Still under 3-laptop rather than 0-common, because the two hosts share only the
# package name. Odin's is the full Cinnamon-shaped install with the thumbnailer
# stack behind it; the phone's is deliberately lean. Keeping them apart also
# scopes the dconf export in this directory: 0-common/1-system/desktop/dconf.nix walks
# 0-common plus the host's own directory, so an export here is loaded on Odin and
# nowhere else.
#
# The bookmarks are not here either. Both file managers read
# ~/.config/gtk-3.0/bookmarks, and that list is shared in
# 0-common/4-apps/system/file-manager.nix. Odin's own Projects, VMs and Backups
# are not bookmarks at all: 3-laptop/1-system/directories.nix bind mounts them so
# they sit with the drives in the sidebar.
#
# Settings are stored in dconf and exported into this folder by
# `nixtool run maintenance/export-dconf`.
{ pkgs, ... }:
{
    home-manager.users.beatlink = {
        home = {
            # nemo-preview, ffmpeg-full and imagemagick are the thumbnailing and
            # preview helpers. They were an option back when this module was
            # shared with a phone on an SD card, because that is a lot of
            # closure to carry. Odin is the only host importing it now, so they
            # are simply listed.
            packages = with pkgs; [
                nemo-with-extensions
                nemo-preview
                ffmpeg-full
                imagemagick
                gettext
            ];

            persistence."/Storage/Apps/System/Nemo" = {
                directories = [
                    ".config/nemo"
                    ".local/share/nemo"
                ];
            };
        };
    };
}
