# KeePassXC
#
# The same database GNOME Secrets opens, from the other client. Secrets is still
# here and still the one that fits the screen -- it is GTK4 and adaptive, where
# KeePassXC is Qt and desktop-sized -- but KeePassXC can do things Secrets
# cannot, and having both costs a package rather than a second database.
#
# What this deliberately does NOT bring over from Odin's copy
# (3-laptop/4-apps/core/keepassxc.nix):
#
#   gnome-keyring    Odin force-disables it so KeePassXC can own
#                    org.freedesktop.secrets by itself, two providers of one bus
#                    name being a fight rather than a fallback. That reasoning
#                    is laptop-only and its own module says so: on this host
#                    Evolution and GNOME Online Accounts keep their credentials
#                    there, and taking the keyring away breaks them.
#
#   Browser          KeePassXC-Browser is a WebExtension. Thor's browser is
#                    Epiphany, which has no equivalent, so the native messaging
#                    host has nothing to talk to and .mozilla is not persisted.
#
#   Autostart        Odin launches it at login for the SSH agent. Nothing here
#                    needs keys in an agent at login, and a Qt window opening
#                    over the shell on a phone is a cost with no return.
#
# So: the client, its settings, and nothing else. .config/keepassxc carries the
# database path and the application's own preferences between boots; the .kdbx
# lives on the data pool and is synced by Syncthing, exactly as on Odin.
#
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = [ pkgs.keepassxc ];

                persistence."/Storage/Apps/Core/KeePassXC" = {
                    directories = [
                        ".config/keepassxc"
                        ".cache/keepassxc"
                    ];
                };
            };
        };
}
