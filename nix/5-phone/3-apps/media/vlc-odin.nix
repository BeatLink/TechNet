# VLC on Odin, displayed here over waypipe, with the sound carried back to this phone.
#
# A second instance, not a launch handed to Odin's copy: VLC's single-instance check is a D-Bus
# name, and each waypipe session runs a dbus-daemon of its own. Odin's wrapper forces
# --avcodec-hw=none, so nothing about decoding has to be restated here.
#
{
    technet.waypipe.apps.vlc-odin = {
        title = "VLC (Odin)";
        host = "odin-waypipe";
        icon = ./vlc.png; # A copy, so the phone does not carry VLC in its closure for one PNG
        categories = [
            "AudioVideo"
            "Video"
            "Player"
        ];

        audio = true; # waypipe carries Wayland alone, so without this every video plays out of Odin
        audioLatency = 400; # Sized for mobile data, where the round trip has swung between 65ms and 334ms

        command = [ "vlc" ];

        # VLC is Qt, so GDK_BACKEND does nothing for it
        environment.QT_QPA_PLATFORM = "wayland";
    };
}
