# Home Assistant
#
# The dashboard as a kiosk window, on the same profile as the Firefox launcher,
# so only one of the two can be open at a time.
#
{
    technet.waypipe.apps.home-assistant = {
        title = "Home Assistant";
        host = "odin-waypipe";
        icon = ./home-assistant.png;

        command = [
            "firefox"
            "--profile"
            "/home/beatlink/.config/mozilla/firefox-waypipe/Personal-Thor"
            "--kiosk"
            "--new-instance"
            "https://home-assistant.heimdall.technet"
        ];

        # Odin's GTK apps otherwise reach for its own session rather than waypipe's display
        environment.GDK_BACKEND = "wayland";
    };
}
