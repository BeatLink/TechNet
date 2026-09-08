# KeePassXC on Heimdall, displayed here over waypipe, on the same database.
#
# It reads a config of its own, seeded by Heimdall's phone-apps module, because there is no tray here
# to hold a window or to get one back.
#
{
    technet.waypipe.apps.keepassxc-heimdall = {
        title = "KeePassXC (Heimdall)";
        host = "heimdall-waypipe";
        icon = ./keepassxc.png;
        categories = [
            "Utility"
            "Security"
            "Qt"
        ];

        command = [
            "keepassxc"
            "--config"
            "/Storage/PhoneApps/KeePassXC/Thor/keepassxc.ini"
            "/Storage/Files/Documents/SecurityDatabase.kdbx"
        ];

        # KeePassXC is Qt, so GDK_BACKEND does nothing for it
        environment.QT_QPA_PLATFORM = "wayland";
    };
}
