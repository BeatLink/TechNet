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
# are appended to it by 3-laptop/1-system/directories.nix.
#
# Settings are stored in dconf and exported into this folder by
# `nixtool run maintenance/export-dconf`.
{ pkgs, ... }:
let
    # nemo-preview embeds a Clutter stage through clutter-gtk, which only knows GdkX11 and segfaults on a Wayland GdkWindow
    nemo-preview = pkgs.nemo-preview.overrideAttrs (_: {
        preFixup = ''
            gappsWrapperArgs+=(--set GDK_BACKEND x11)
        '';
    });
in
{
    home-manager.users.beatlink = {
        home = {
            # nemo-preview, ffmpeg-full and imagemagick are the thumbnailing and preview helpers; let bindings win over with, so nemo-preview is the wrapped one
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
