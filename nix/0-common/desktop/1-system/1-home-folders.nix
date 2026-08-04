# Home folders
#
# The XDG user directories point into /Storage/Files rather than ~, so the data
# lives on the data pool and survives a wipe of the root filesystem.
#
# This is also what gives Portfolio its shortcuts. Portfolio's places list is
# hardcoded in places.py -- Home, the filesystem root, the XDG directories,
# Trash, and devices found from mount points and fstab. It reads neither dconf
# nor the GTK bookmarks file, so pointing the XDG directories at /Storage is the
# only way to put that content one tap away in it.
#
{
    home-manager.users.beatlink = {
        xdg.userDirs = {
            enable = true;
            desktop = "/Storage/Files/Desktop";
            documents = "/Storage/Files/Documents";
            download = "/Storage/Files/Downloads";
            music = "/Storage/Files/Music";
            pictures = "/Storage/Files/Pictures";
            videos = "/Storage/Files/Videos";
        };
    };
}
