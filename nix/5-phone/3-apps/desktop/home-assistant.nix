# Home Assistant
#
# The dashboard as a kiosk window. Kiosk is a process-wide flag once set, so
# this shares a profile with the other dashboard rather than with the browser,
# whose windows would otherwise come up fullscreen after this one had run.
#
{
    technet.waypipe.apps.home-assistant = {
        title = "Home Assistant";
        host = "heimdall-waypipe";
        icon = ./home-assistant.png;

        command = [
            "firefox"
            "--profile"
            "/Storage/PhoneApps/Firefox/Thor/Kiosk"
            "--kiosk"
            "--new-window"
            "https://home-assistant.heimdall.technet"
        ];

        # Pinned so the toolkit takes waypipe's display rather than probing for another
        environment.GDK_BACKEND = "wayland";
    };
}
