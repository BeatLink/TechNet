# Nemo
#
# Odin's file manager. Nemo is Cinnamon's, built for a mouse and a wide window,
# and this is a machine that has both. Thor also runs it now
# (5-phone/3-apps/system/nemo.nix), having gone to Nautilus and back when GTK4
# turned out to render in software on a Mali-400.
#
# Still under 3-laptop rather than 0-common/desktop, because the two hosts share
# only the package name. Odin's is the full Cinnamon-shaped install with the
# thumbnailer stack behind it; the phone's is deliberately lean. Keeping them
# apart also scopes the dconf export in this directory:
# 0-common/desktop/1-system/3-dconf walks the shared desktop directory plus the
# host's own, so an export here is loaded on Odin and nowhere else.
#
# The bookmarks are not here. Both file managers read
# ~/.config/gtk-3.0/bookmarks, so that list stays shared in
# 0-common/desktop/4-apps/system/file-manager.nix and this only adds the three
# places that exist on this machine and not on the phone.
#
# Settings are stored in dconf and exported into this folder by
# `nixtool run maintenance/export-dconf`.
{ lib, pkgs, ... }:
{
    # mkAfter so these land below the shared entries in the sidebar rather than
    # wherever module import order happens to put them.
    technet.desktop.fileManager.bookmarks = lib.mkAfter ''
        file:///Storage/Files/Projects Projects
        file:///Storage/Files/VMs VMs
        file:///Storage/Files/Backups Backups
    '';

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
