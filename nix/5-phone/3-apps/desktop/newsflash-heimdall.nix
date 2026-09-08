# NewsFlash on Heimdall, displayed here over waypipe, on the feeds and read state kept in that host's home.
#
# Nothing here separates it from a second instance, because Heimdall runs no copy of its own: each waypipe session gets its own dbus-daemon, so the
# GtkApplication id this registers is held by nothing else.
#
{
    technet.waypipe.apps.newsflash-heimdall = {
        title = "NewsFlash (Heimdall)";
        host = "heimdall-waypipe";
        icon = ./newsflash.png; # A copy, so the phone does not carry NewsFlash in its closure for one PNG
        categories = [
            "Network"
            "News"
            "Feed"
        ];

        command = [ "io.gitlab.news_flash.NewsFlash" ];

        # Pinned so the toolkit takes waypipe's display rather than probing for another
        environment.GDK_BACKEND = "wayland";
    };
}
