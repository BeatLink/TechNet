# Firefox on Odin, displayed here over waypipe, on a copy of Odin's Personal
# profile, so the two run at once.
#
# Passed by path rather than -P: a directory absent from profiles.ini gets no
# toolkit profile entry, and so no "account already in use" refusal from Sync.
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
            "--profile"
            "/home/beatlink/.config/mozilla/firefox-waypipe/Personal-Thor"
            "--new-instance"
        ];

        # Odin's GTK apps otherwise reach for its own session rather than waypipe's display
        environment.GDK_BACKEND = "wayland";
    };
}
