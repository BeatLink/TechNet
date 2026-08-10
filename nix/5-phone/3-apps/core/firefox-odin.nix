# Firefox on Odin, displayed here over waypipe, on Odin's own Personal profile.
#
# Odin's Firefox has to be closed first -- one profile cannot be open in two
# processes, and --new-instance turns that into a dialog here rather than a
# window that silently opens on the laptop instead.
#
{
    technet.waypipe.apps.firefox-odin = {
        title = "Firefox (Odin)";
        host = "odin-waypipe";
        icon = ./firefox.png;
        categories = [
            "Network"
            "WebBrowser"
        ];

        command = [
            "firefox"
            "-P"
            "Personal"
            "--new-instance"
        ];

        # Odin's GTK apps otherwise reach for its own session rather than waypipe's display
        environment.GDK_BACKEND = "wayland";
    };
}
