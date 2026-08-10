# KeePassXC on Odin, displayed here over waypipe, on the same database.
#
# Odin autostarts its own instance for the SSH agent; single instance is off in
# KeePassXC's own settings there, so this one opens here rather than handing over.
#
{
    technet.waypipe.apps.keepassxc-odin = {
        title = "KeePassXC (Odin)";
        host = "odin-waypipe";
        icon = ./keepassxc.png;
        categories = [
            "Utility"
            "Security"
        ];

        command = [
            "keepassxc"
            "/Storage/Files/Documents/SecurityDatabase.kdbx"
        ];

        # KeePassXC is Qt, so GDK_BACKEND does nothing for it
        environment.QT_QPA_PLATFORM = "wayland";
    };
}
