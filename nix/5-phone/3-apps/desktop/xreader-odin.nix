# XReader on Odin, displayed here over waypipe, on Odin's own documents and settings.
#
# Nothing keeps it from being a second instance: each waypipe session gets its own dbus-daemon, so
# the GtkApplication id it registers is not the one Odin's copy holds on Odin's bus.
#
{
    technet.waypipe.apps.xreader-odin = {
        title = "XReader (Odin)";
        host = "odin-waypipe";
        icon = ./xreader.png; # A copy, so the phone does not carry xreader in its closure for one PNG
        categories = [
            "Office"
            "Viewer"
            "Graphics"
        ];

        command = [ "xreader" ]; # No path, because xreader opens documents rather than folders and lands on its recent list

        # Odin's GTK apps otherwise reach for its own session rather than waypipe's display
        environment.GDK_BACKEND = "wayland";
    };
}
