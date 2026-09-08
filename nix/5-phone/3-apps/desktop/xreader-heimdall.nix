# XReader on Heimdall, displayed here over waypipe, on that host's own documents and settings.
#
# Nothing here separates it from a second instance, because Heimdall runs no copy of its own: each waypipe session gets its own dbus-daemon, so the
# GtkApplication id this registers is held by nothing else.
#
{
    technet.waypipe.apps.xreader-heimdall = {
        title = "XReader (Heimdall)";
        host = "heimdall-waypipe";
        icon = ./xreader.png; # A copy, so the phone does not carry xreader in its closure for one PNG
        categories = [
            "Office"
            "Viewer"
            "Graphics"
        ];

        command = [ "xreader" ]; # No path, because xreader opens documents rather than folders and lands on its recent list

        # Pinned so the toolkit takes waypipe's display rather than probing for another
        environment.GDK_BACKEND = "wayland";
    };
}
