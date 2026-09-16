# Xed on Heimdall, displayed here over waypipe, editing that host's files.
#
# Nothing here separates it from a second instance, because Heimdall runs no copy of its own: each waypipe session gets its own dbus-daemon, so the
# GtkApplication id this registers is held by nothing else.
#
{
    technet.waypipe.apps.xed-heimdall = {
        title = "Xed (Heimdall)";
        host = "heimdall-waypipe";
        icon = "accessories-text-editor"; # A theme name rather than a copy, because xed ships no icon of its own and names this one too
        categories = [
            "Utility"
            "TextEditor"
        ];

        command = [ "xed" ];

        # Pinned so the toolkit takes waypipe's display rather than probing for another
        environment.GDK_BACKEND = "wayland";
    };
}
