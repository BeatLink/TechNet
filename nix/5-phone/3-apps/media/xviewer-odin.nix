# XViewer on Odin, displayed here over waypipe, on Odin's own pictures and settings.
#
# Nothing keeps it from being a second instance: each waypipe session gets its own dbus-daemon, so
# the GtkApplication id it registers is not the one Odin's copy holds on Odin's bus.
#
{
    technet.waypipe.apps.xviewer-odin = {
        title = "XViewer (Odin)";
        host = "odin-waypipe";
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

        # Odin's GTK apps otherwise reach for its own session rather than waypipe's display
        environment.GDK_BACKEND = "wayland";
    };
}
