# Quod Libet on Heimdall, displayed here over waypipe, with the sound carried back to this phone.
#
# Its own user directory holds the control socket a launch is handed to, so keeping it here rather
# than at the default means a second launch starts its own process instead of being handed to one
# whose waypipe session has already ended. The library is built there on first run.
#
{
    technet.waypipe.apps.quodlibet-heimdall = {
        title = "Quod Libet (Heimdall)";
        host = "heimdall-waypipe";
        icon = ./quodlibet.png; # A copy, so the phone does not carry Quod Libet in its closure for one PNG
        categories = [
            "AudioVideo"
            "Audio"
            "Player"
        ];

        audio = true; # waypipe carries Wayland alone, so without this every track plays out of Heimdall
        audioLatency = 400; # Sized for mobile data, where the round trip has swung between 65ms and 334ms

        command = [ "quodlibet" ];

        environment = {
            QUODLIBET_USERDIR = "/Storage/PhoneApps/QuodLibet/Thor"; # Holds the control socket, so a launch is not handed to a session that has ended
            GDK_BACKEND = "wayland"; # Pinned so the toolkit takes waypipe's display rather than probing for another
        };
    };
}
