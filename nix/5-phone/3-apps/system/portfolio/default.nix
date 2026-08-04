# Portfolio
#
# The touch-first file manager. Nemo alongside it is the desktop-style one.
#
# Settings are stored in dconf and exported into this folder by
# `nixtool run maintenance/export-dconf` -- see dconf-settings.json. The schema
# is small: dev.tchx84.Portfolio has only `show-hidden` and `sort-order`.
#
# There is deliberately no bookmark for /Storage here. Portfolio's places list
# is hardcoded in places.py -- Home, the filesystem root, the XDG user
# directories, Trash, and devices discovered from mount points and fstab. It
# reads neither dconf nor the GTK bookmarks file, so /Storage can only appear
# via that device list, which it should, being a real mount with an fstab entry.
#
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = [
                    pkgs.portfolio-filemanager
                ];
                persistence."/Storage/Apps/System/Portfolio" = {
                    directories = [
                        ".local/share/dev.tchx84.Portfolio"
                    ];

                };
            };
        };
}
