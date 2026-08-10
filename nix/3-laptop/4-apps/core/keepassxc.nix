# KeePassXC
#
# The password database itself is not here -- it is a file on the data pool,
# synced between hosts by Syncthing like any other document. What this module
# provides is the client, and the two integrations that make it more than a
# password list:
#
#   SSH agent       KeePassXC does not run an agent of its own. It adds keys
#                   from the unlocked database to whatever agent SSH_AUTH_SOCK
#                   points at, which here is gcr-ssh-agent at
#                   /run/user/1000/gcr/ssh. That is why beatlink has no private
#                   key on disk anywhere and can still reach every host: the
#                   keys live in the database and exist only in the agent.
#
#   Browser         Firefox talks to KeePassXC over native messaging, whose
#                   manifest KeePassXC writes into
#                   ~/.mozilla/native-messaging-hosts when the integration is
#                   enabled. Persisting that directory is what makes it survive
#                   a rollback.
#
# Both are settings inside the application, stored in .config/keepassxc, so
# persisting that is what carries them between boots. Nothing here can turn
# them on -- this module makes them possible and durable, not configured.
#
# Laptop-only deliberately. Thor reads the same database with GNOME Secrets,
# which is the adaptive client and the right shape for a phone; KeePassXC is Qt
# and desktop-sized. The phone is a quick way to reach the same resources rather
# than a second copy of this machine.
#
# gnome-keyring is turned off because KeePassXC can serve
# org.freedesktop.secrets itself and two providers of one bus name is a fight
# rather than a fallback. That is right here and wrong on Thor, where Evolution
# and GNOME Online Accounts would lose their credential store -- another reason
# this is not shared. The SSH agent is unaffected either way: gcr-ssh-agent is a
# separate service and stays running with gnome-keyring-daemon disabled.
#
# kwallet is disabled for the same reason from the KDE side: nothing here uses
# it, and it otherwise inserts itself into the login PAM stack.
#
{ lib, ... }:
{
    services.gnome.gnome-keyring.enable = lib.mkForce false;
    security.pam.services.login.kwallet.enable = false;

    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            services.gnome-keyring.enable = lib.mkForce false;

            home = {
                packages = [ pkgs.keepassxc ];

                persistence."/Storage/Apps/Core/KeePassXC" = {
                    directories = [
                        ".config/keepassxc"
                        ".cache/keepassxc"
                        ".mozilla/native-messaging-hosts"
                    ];
                };

                file.".config/autostart/org.keepassxc.KeePassXC.desktop".source =
                    "${pkgs.keepassxc}/share/applications/org.keepassxc.KeePassXC.desktop";
            };
        };
}
