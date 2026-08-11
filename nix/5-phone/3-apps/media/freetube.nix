# FreeTube on Odin, displayed here over waypipe.
#
# Its own Electron user-data dir is what makes it a second process; subscriptions, history and
# settings live in there, so this instance keeps a set separate from Odin's.
#
{
    technet.waypipe.apps.freetube = {
        title = "FreeTube";
        host = "odin-waypipe";
        icon = ./freetube.png; # A copy, so the phone does not carry Electron in its closure for one PNG
        categories = [
            "AudioVideo"
            "Video"
            "Network"
        ];

        audio = true; # waypipe carries Wayland alone, so without this the sound comes out of Odin

        command = [
            "freetube"
            # The `=` form is required: Chromium's parser reads a separate word as a positional arg, and FreeTube treats those as URLs to open
            "--user-data-dir=/home/beatlink/.config/freetube-waypipe/Thor"
            # The freetube wrapper passes no ozone platform at all, and Electron defaults to X11, which leaves a black window on the phone
            "--ozone-platform=wayland"
            "--wayland-text-input-version=3"
        ];

        # The freetube wrapper reads this, together with waypipe's WAYLAND_DISPLAY, to add Wayland decorations and the IME flag the phone's keyboard types through
        environment.NIXOS_OZONE_WL = "1";
    };
}
