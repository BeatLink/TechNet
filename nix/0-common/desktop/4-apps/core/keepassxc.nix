# KeePassXC
#
# The password database itself is not here -- it is a file on the data pool,
# synced between hosts by Syncthing like any other document. What this module
# provides is the client, and the two integrations that make it more than a
# password list:
#
#   SSH agent       KeePassXC does not run an agent of its own. It adds keys
#                   from the unlocked database to whatever agent SSH_AUTH_SOCK
#                   points at, which on both desktops is gcr-ssh-agent at
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
# Shared rather than laptop-only because the phone needs exactly the same two
# things. Thor reaches the other hosts over sftp from Nemo, which runs as
# beatlink and so needs a key in the session agent, and GNOME Secrets -- which
# Thor also has, for reading the same database on a small screen -- has no
# agent integration at all. That is a KeePassXC feature.
#
# Deliberately NOT here: disabling gnome-keyring. Odin does that in its own
# module, because KeePassXC can serve org.freedesktop.secrets itself and two
# providers of one bus name is a fight. Thor keeps gnome-keyring, because
# Evolution and GNOME Online Accounts are running there and would lose their
# credential store the moment it went away.
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
                        ".mozilla/native-messaging-hosts"
                    ];
                };

                # Autostarted because both integrations are useless until the
                # database is unlocked, and neither Nemo nor Firefox can prompt
                # for it -- an sftp bookmark would simply fail to authenticate.
                file.".config/autostart/org.keepassxc.KeePassXC.desktop".source =
                    "${pkgs.keepassxc}/share/applications/org.keepassxc.KeePassXC.desktop";
            };
        };
}
