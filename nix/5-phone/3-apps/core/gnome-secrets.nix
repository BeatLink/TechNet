# GNOME Secrets
#
# The phone's password manager. Not a different format from Odin's -- Secrets
# reads and writes the same .kdbx KeePass database KeePassXC does, so one file
# can serve both hosts. What differs is the front end: Secrets is GTK4 and
# adaptive, so it reflows for a 411x823 screen, where KeePassXC's Qt windows do
# not.
#
# It deliberately does NOT replace KeePassXC on Odin. Browser integration is a
# KeePassXC feature -- its native messaging host plus the KeePassXC-Browser
# extension -- and Secrets has no equivalent. Odin keeps KeePassXC for that;
# see 3-laptop/4-apps/core/keepassxc.nix.
#
# Nor could this host have it either way: Thor runs firefox-mobile, which is a
# callPackage of nixpkgs' mobile-config.nix and calls wrapFirefox with a fixed
# argument set, so there is no nativeMessagingHosts to pass through without
# forking that package.
#
# Persisted like the other apps. `.local/share/secrets` holds the app's own
# state and the path to the last opened database; the database itself is
# wherever it is kept on /Storage, and is not this module's business.
#
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ gnome-secrets ];
                persistence."/Storage/Apps/Core/Secrets" = {
                    directories = [
                        ".local/share/secrets"
                        ".cache/secrets"
                    ];

                };
            };
        };
}
