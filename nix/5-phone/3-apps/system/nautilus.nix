# Nautilus -- the phone's file manager, replacing Nemo.
#
# Nemo is Cinnamon's file manager and was shared with Odin. It works on a phone
# in the sense that it starts, but it is a GTK3 application built around a
# mouse, a wide window and a menu bar, and none of those exist here. Nautilus is
# GTK4/libadwaita and adaptive -- it collapses its sidebar and reflows to a
# narrow window, which is the whole reason GNOME's own mobile work uses it.
#
# Same reasoning as GNOME Secrets over KeePassXC in 3-apps/core: the phone
# should reach the same files as Odin without being a second copy of Odin, so it
# takes the adaptive client rather than the desktop one.
#
# The bookmarks come from 0-common/desktop/4-apps/system/file-manager.nix and
# are not restated here. Both file managers read ~/.config/gtk-3.0/bookmarks, so
# the sidebar is the same list of places on both hosts, including the sftp
# entries back to the other machines.
#
# No dconf export, because there are no preferences worth pinning yet. To add
# one later, create a dconf-settings.json here holding `"host": "Thor"` and
# `/org/gnome/nautilus/`, then run `nixtool run maintenance/export-dconf` --
# the host tag is what makes it dump over ssh from the phone rather than from
# whichever machine the command runs on. 3-apps/core/tangram is the worked
# example.
#
# Create the pair in that order and in one go. The importer in
# 0-common/desktop/1-system/3-dconf interpolates the .dconf path into a systemd
# ExecStart, so a settings file without its matching export fails evaluation
# rather than being skipped.
#
# Deliberately lean: no nautilus-python, no extensions, no thumbnailer stack.
# Odin carries ffmpeg-full and imagemagick for Nemo's previews and that is a lot
# of closure for an SD card.
{ pkgs, ... }:
{
    home-manager.users.beatlink = {
        home = {
            packages = [ pkgs.nautilus ];

            persistence."/Storage/Apps/System/Nautilus" = {
                directories = [
                    ".config/nautilus"
                    ".local/share/nautilus"
                ];
            };
        };
    };
}
