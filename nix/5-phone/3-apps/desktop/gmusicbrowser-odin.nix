# gmusicbrowser on Odin, displayed here over waypipe, with the sound carried back to this phone.
#
# Its own default folder is what makes it a second process: gmusicbrowser hands a launch to the copy
# holding the gmusicbrowser.fifo named pipe, and moving that folder gives this instance a pipe, a
# gmbrc and a library of its own. The library is built in this folder on first run, by pointing it
# at the music on Odin's pool.
#
{
    technet.waypipe.apps.gmusicbrowser-odin = {
        title = "gmusicbrowser (Odin)";
        host = "odin-waypipe";
        icon = ./gmusicbrowser.png; # A copy, so the phone does not carry gmusicbrowser in its closure for one PNG
        categories = [
            "AudioVideo"
            "Audio"
            "Player"
        ];

        audio = true; # waypipe carries Wayland alone, so without this every track plays out of Odin
        audioLatency = 400; # Sized for mobile data, where the round trip has swung between 65ms and 334ms

        command = [
            "gmusicbrowser"
            "-C"
            "/Storage/PhoneApps/GMusicBrowser/Thor" # A folder rather than a file, which moves the fifo and the gmbrc together
            "-id"
            "thor" # Separates the window roles and the DBus name as well, so nothing about this instance answers for Odin's
        ];

        environment.GDK_BACKEND = "wayland"; # Odin's GTK apps otherwise reach for its own session rather than waypipe's display
    };
}
