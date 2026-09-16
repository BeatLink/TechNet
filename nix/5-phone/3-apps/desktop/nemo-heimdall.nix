# Nemo on Heimdall, displayed here over waypipe, browsing that host's own storage.
#
# Nothing here separates it from a second instance, because Heimdall runs no copy of its own: each waypipe session gets its own dbus-daemon, so the
# GtkApplication id this registers is held by nothing else.
#
# The sidebar is the shared list from 0-common/4-apps/system/file-manager.nix, which on Heimdall reaches the other hosts over sftp -- this phone
# included, so the phone's own card is one bookmark away.
#
{
    technet.waypipe.apps.nemo-heimdall = {
        title = "Nemo (Heimdall)";
        host = "heimdall-waypipe";
        icon = "system-file-manager"; # A theme name rather than a copy, because Mint-Y-Aqua carries this one and nemo's own entry names it as well
        categories = [
            "System"
            "FileTools"
            "FileManager"
        ];

        command = [
            "nemo"
            "/Storage/Files" # A place to open into, because a launch with no argument lands in a home that holds none of the phone's files
        ];

        # Pinned so the toolkit takes waypipe's display rather than probing for another
        environment.GDK_BACKEND = "wayland";
    };
}
