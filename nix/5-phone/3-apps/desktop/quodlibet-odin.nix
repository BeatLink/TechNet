# Quod Libet on Odin, displayed here over waypipe, with the sound carried back to this phone.
#
# Its own user directory is what makes it a second process: Quod Libet talks to a running copy
# through a control socket kept in there, and would otherwise hand the launch over and exit. The
# library is rebuilt in this directory on first run, by pointing it at the music on Odin's pool.
#
{
    technet.waypipe.apps.quodlibet-odin = {
        title = "Quod Libet (Odin)";
        host = "odin-waypipe";
        icon = ./quodlibet.png; # A copy, so the phone does not carry Quod Libet in its closure for one PNG
        categories = [
            "AudioVideo"
            "Audio"
            "Player"
        ];

        audio = true; # waypipe carries Wayland alone, so without this every track plays out of Odin
        audioLatency = 400; # Sized for mobile data, where the round trip has swung between 65ms and 334ms

        command = [ "quodlibet" ];

        environment = {
            QUODLIBET_USERDIR = "/Storage/PhoneApps/QuodLibet/Thor"; # Holds the control socket, so Odin's running copy does not adopt the launch
            GDK_BACKEND = "wayland"; # Odin's GTK apps otherwise reach for its own session rather than waypipe's display
        };
    };
}
