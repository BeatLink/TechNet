# XViewer on Heimdall, displayed here over waypipe, on that host's own pictures and settings.
#
# Nothing here separates it from a second instance, because Heimdall runs no copy of its own: each waypipe session gets its own dbus-daemon, so the
# GtkApplication id this registers is held by nothing else.
#
{
    technet.waypipe.apps.xviewer-heimdall = {
        title = "XViewer (Heimdall)";
        host = "heimdall-waypipe";
        icon = ./xviewer.png; # A copy, so the phone does not carry xviewer in its closure for one PNG
        categories = [
            "Graphics"
            "Viewer"
            "Utility"
        ];

        command = [
            "xviewer"
            "/Storage/Files/Pictures" # A collection to open into, because a launch with no argument lands on an empty window
        ];

        # Pinned so the toolkit takes waypipe's display rather than probing for another
        environment.GDK_BACKEND = "wayland";
    };
}
