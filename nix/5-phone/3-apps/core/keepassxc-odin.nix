# KeePassXC on Odin, displayed here over waypipe, on the same database.
#
# Odin autostarts its own instance for the SSH agent, so this one needs the
# separate config that turns single-instance off -- without it KeePassXC hands
# over to that instance and the window opens on the laptop.
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
            "--config"
            "/home/beatlink/.config/keepassxc-waypipe.ini"
            "/Storage/Files/Documents/SecurityDatabase.kdbx"
        ];

        # KeePassXC is Qt, so GDK_BACKEND does nothing for it
        environment.QT_QPA_PLATFORM = "wayland";
    };
}
