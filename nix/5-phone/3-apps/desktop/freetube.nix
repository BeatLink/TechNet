# FreeTube on Heimdall, displayed here over waypipe.
#
# Its own Electron user-data dir holds the single-instance lock, so keeping it here rather than at
# the default means a second launch starts its own process instead of being handed to one whose
# waypipe session has already ended. Subscriptions, history and settings live in there.
#
{
    technet.waypipe.apps.freetube = {
        title = "FreeTube";
        host = "heimdall-waypipe";
        icon = ./freetube.png; # A copy, so the phone does not carry Electron in its closure for one PNG
        categories = [
            "AudioVideo"
            "Video"
            "Network"
        ];

        audio = true; # waypipe carries Wayland alone, so without this the sound comes out of Heimdall
        audioLatency = 400; # Sized for mobile data, where the round trip has swung between 65ms and 334ms

        command = [
            "freetube"
            # The `=` form is required: Chromium's parser reads a separate word as a positional arg, and FreeTube treats those as URLs to open
            "--user-data-dir=/Storage/PhoneApps/FreeTube/Thor"
            # The freetube wrapper passes no ozone platform at all, and Electron defaults to X11, which leaves a black window on the phone
            "--ozone-platform=wayland"
            "--wayland-text-input-version=3"
        ];

        # The freetube wrapper reads this, together with waypipe's WAYLAND_DISPLAY, to add Wayland decorations and the IME flag the phone's keyboard types through
        environment.NIXOS_OZONE_WL = "1";
    };
}
