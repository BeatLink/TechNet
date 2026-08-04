# Home folders
#
# The XDG user directories point into /Storage/Files rather than ~, so the data
# lives on the data pool and survives a wipe of the root filesystem.
#
# It also decides where applications offer to save. GTK's file chooser reads
# these, so a browser download or a "save as" lands on the data pool rather than
# in the root filesystem, which on these hosts is rolled back to a blank
# snapshot at every boot.
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
