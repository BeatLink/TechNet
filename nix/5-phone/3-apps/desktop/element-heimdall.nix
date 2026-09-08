# Element on Heimdall, displayed here over waypipe.
#
# --profile-dir holds Electron's single-instance lock, so keeping it here rather than at the default
# means a second launch starts its own process instead of being handed to one whose waypipe session
# has already ended. A separate directory is a separate device in Matrix's eyes, verified on its own.
#
{
    technet.waypipe.apps.element-heimdall = {
        title = "Element (Heimdall)";
        host = "heimdall-waypipe";
        icon = ./element.png; # A copy, so the phone does not carry Electron in its closure for one PNG
        categories = [
            "Network"
            "InstantMessaging"
            "Chat"
        ];

        audio = true; # waypipe carries Wayland alone, so without this calls and notifications come out of Heimdall
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
