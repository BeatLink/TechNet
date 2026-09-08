# Pix on Heimdall, displayed here over waypipe, on that host's own library and settings.
#
# Nothing here separates it from a second instance, because Heimdall runs no copy of its own: each waypipe session gets its own dbus-daemon, so the
# GtkApplication id this registers is held by nothing else.
#
{
    technet.waypipe.apps.pix-heimdall = {
        title = "Pix (Heimdall)";
        host = "heimdall-waypipe";
        icon = ./pix.png; # A copy, so the phone does not carry pix in its closure for one PNG
        categories = [
            "Graphics"
            "Viewer"
            "Photography"
        ];

        command = [
            "pix"
            "/Storage/Files/Pictures" # A library to open into, because pix otherwise browses whichever folder it was left in
        ];

        # Pinned so the toolkit takes waypipe's display rather than probing for another
        environment.GDK_BACKEND = "wayland";
    };
}
