# Remote builder access
#
# Odin offloads aarch64 builds here, since this is the only native aarch64 host.
# Its nix-daemon runs as root and connects as beatlink, using Odin's SSH host key
# as the client key -- so what is authorised here is Odin's host identity rather
# than a person's key. beatlink is already a trusted user, which is what lets the
# daemon hand off a build.
#
{
    users.users.beatlink.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINnDCoaEbXWh0rJshd2alkRQrGo+jsmKssXXMVbivl4p Odin"
    ];
}
