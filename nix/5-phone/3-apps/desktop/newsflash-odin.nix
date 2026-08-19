# NewsFlash on Odin, displayed here over waypipe, on Odin's own feeds and read state.
#
# Nothing keeps it from being a second instance: each waypipe session gets its own dbus-daemon, so
# the GtkApplication id it registers is not the one Odin's copy holds on Odin's bus.
#
{
    technet.waypipe.apps.newsflash-odin = {
        title = "NewsFlash (Odin)";
        host = "odin-waypipe";
        icon = ./newsflash.png; # A copy, so the phone does not carry NewsFlash in its closure for one PNG
        categories = [
            "Network"
            "News"
            "Feed"
        ];

        # Both instances write one sqlite database, which is safe only because both processes run on Odin's own filesystem
        command = [ "io.gitlab.news_flash.NewsFlash" ];

        # Odin's GTK apps otherwise reach for its own session rather than waypipe's display
        environment.GDK_BACKEND = "wayland";
    };
}
