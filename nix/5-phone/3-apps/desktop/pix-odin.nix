# Pix on Odin, displayed here over waypipe, on Odin's own library and settings.
#
# Nothing keeps it from being a second instance: each waypipe session gets its own dbus-daemon, so
# the GtkApplication id it registers is not the one Odin's copy holds on Odin's bus.
#
{
    technet.waypipe.apps.pix-odin = {
        title = "Pix (Odin)";
        host = "odin-waypipe";
        icon = ./pix.png; # A copy, so the phone does not carry pix in its closure for one PNG
        categories = [
            "Graphics"
            "Viewer"
            "Photography"
        ];

        command = [
            "pix"
            "/Storage/Files/Pictures" # A library to open into, because pix otherwise browses whichever folder Odin's copy left it in
        ];

        # Odin's GTK apps otherwise reach for its own session rather than waypipe's display
        environment.GDK_BACKEND = "wayland";
    };
}
