# Element on Odin, displayed here over waypipe.
#
# --profile-dir is what makes it a second process: Electron's single-instance lock is held on the
# user data directory, so Odin's copy would otherwise adopt the launch and draw it on its own screen.
# A separate directory means a separate device in Matrix's eyes, so this one is verified on its own.
#
{
    technet.waypipe.apps.element-odin = {
        title = "Element (Odin)";
        host = "odin-waypipe";
        icon = ./element.png; # A copy, so the phone does not carry Electron in its closure for one PNG
        categories = [
            "Network"
            "InstantMessaging"
            "Chat"
        ];

        audio = true; # waypipe carries Wayland alone, so without this calls and notifications come out of Odin
        audioLatency = 400; # Sized for mobile data, where the round trip has swung between 65ms and 334ms

        command = [
            "element-desktop"
            "--profile-dir"
            "/Storage/PhoneApps/Element/Thor"
            # Overrides the wrapper's --ozone-platform-hint=auto, which resolves to X11 over ssh because XDG_SESSION_TYPE is tty there, and leaves a black window
            "--ozone-platform=wayland"
        ];

        # The element-desktop wrapper reads this, together with waypipe's WAYLAND_DISPLAY, to add Wayland decorations and the IME flag the phone's keyboard types through
        environment.NIXOS_OZONE_WL = "1";
    };
}
