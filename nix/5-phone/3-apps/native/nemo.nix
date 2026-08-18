# Nemo -- the phone's file manager, replacing Nautilus.
#
# Nautilus was chosen for this host because it is GTK4/libadwaita and adaptive:
# it collapses its sidebar and reflows to a narrow window, which is why GNOME's
# own mobile work uses it. Nemo is Cinnamon's, shared with Odin, and is built
# around a mouse, a wide window and a menu bar -- none of which exist here.
#
# It is here anyway because the toolkit outranks the layout on this hardware.
# lima on the Mali-400 is GLES 2.0, GTK4 asks for GLES 3.0 and is refused, so
# every GTK4 application falls back to rasterising its scene graph in software.
# GTK3 draws with cairo directly and has no scene graph at all. An adaptive
# window that renders in software is worse to use than a desktop-shaped one that
# does not, and toolkit-comparison.nix is where that was measured.
#
# The bookmarks come from 0-common/4-apps/system/file-manager.nix and
# are not restated here. Both file managers read ~/.config/gtk-3.0/bookmarks, so
# the sidebar is the same list of places as on Odin, including the sftp entries
# back to the other machines.
#
# Deliberately lean: no extensions and no thumbnailer stack. Odin carries
# ffmpeg-full and imagemagick for Nemo's previews and that is a lot of closure
# for an SD card.
{ pkgs, ... }:
{
    home-manager.users.beatlink = {
        home = {
            packages = [ pkgs.nemo ];

            persistence."/Storage/Apps/System/Nemo" = {
                directories = [
                    ".config/nemo"
                    ".local/share/nemo"
                ];
            };
        };
    };
}
