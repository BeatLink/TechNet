# KeePassXC, laptop-specific parts
#
# The client itself, its persistence, and the browser and SSH agent
# integrations are shared now -- see 0-common/desktop/4-apps/core/keepassxc.nix.
# What is left here is the one piece that is not safe to share.
#
# KeePassXC can serve org.freedesktop.secrets itself, and two providers of one
# bus name is a fight rather than a fallback, so gnome-keyring is turned off to
# leave the field clear. That is right for this host and wrong for Thor, where
# Evolution and GNOME Online Accounts are running and would lose their
# credential store the moment the keyring went away.
#
# Note this is not what provides the SSH agent on either host. That is
# gcr-ssh-agent, at /run/user/1000/gcr/ssh, which is a separate service and
# stays running with gnome-keyring-daemon disabled -- confirmed on both.
#
# kwallet is disabled for the same reason from the KDE side: nothing here uses
# it, and it otherwise inserts itself into the login PAM stack.
#
{ lib, ... }:
{
    services.gnome.gnome-keyring.enable = lib.mkForce false;
    security.pam.services.login.kwallet.enable = false;

    home-manager.users.beatlink = {
        services.gnome-keyring.enable = lib.mkForce false;
    };
}
