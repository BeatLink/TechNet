# KeePassXC on Odin, displayed here over waypipe, on the same database.
#
# Odin autostarts its own instance for the SSH agent, minimized to its tray. This
# one reads a config of its own, seeded by Odin's module, because there is no tray
# here to hold a window or to get one back.
#
{
    technet.waypipe.apps.keepassxc-odin = {
        title = "KeePassXC (Odin)";
        host = "odin-waypipe";
        icon = ./keepassxc.png;
        categories = [
            "Utility"
            "Security"
            "Qt"
        ];

        command = [
            "keepassxc"
            "--config"
            "/home/beatlink/.config/keepassxc-waypipe/Thor/keepassxc.ini"
            "/Storage/Files/Documents/SecurityDatabase.kdbx"
        ];

        # KeePassXC is Qt, so GDK_BACKEND does nothing for it
        environment.QT_QPA_PLATFORM = "wayland";
    };
}
