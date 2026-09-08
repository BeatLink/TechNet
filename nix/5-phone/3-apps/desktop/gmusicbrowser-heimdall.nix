# gmusicbrowser on Heimdall, displayed here over waypipe, with the sound carried back to this phone.
#
# Its own default folder holds the gmusicbrowser.fifo named pipe, which is what a launch is handed to; keeping it here rather than at the default
# means a second launch cannot be adopted by a copy whose waypipe session has already ended. The gmbrc and the library sit in the same folder, and
# the library is built there on first run by pointing it at the music on Heimdall's pool.
#
{
    technet.waypipe.apps.gmusicbrowser-heimdall = {
        title = "gmusicbrowser (Heimdall)";
        host = "heimdall-waypipe";
        icon = ./gmusicbrowser.png; # A copy, so the phone does not carry gmusicbrowser in its closure for one PNG
        categories = [
            "AudioVideo"
            "Audio"
            "Player"
        ];

        audio = true; # waypipe carries Wayland alone, so without this every track plays out of Heimdall
        audioLatency = 400; # Sized for mobile data, where the round trip has swung between 65ms and 334ms

        command = [
            "gmusicbrowser"
            "-C"
            "/Storage/PhoneApps/GMusicBrowser/Thor" # A folder rather than a file, which moves the fifo and the gmbrc together
            "-id"
            "thor" # Separates the window roles and the DBus name as well
        ];

        environment.GDK_BACKEND = "wayland"; # Pinned so the toolkit takes waypipe's display rather than probing for another
    };
}
