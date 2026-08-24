# Always On Top
#
# Cinnamon has no per-application window rules: its "Always on Top" is a title bar toggle on one window that
# is forgotten when that window closes. This ships a small extension of our own that sets the state instead,
# so KeePassXC stays reachable over whatever is being filled in.
#
# It installs into the system data directory rather than ~/.local/share/cinnamon, which holds the spices
# downloaded from the Cinnamon site. Cinnamon searches both, and this way the extension is part of the
# generation rather than a file that has to survive on its own.
#
{ pkgs, ... }:
let
    uuid = "always-on-top@technet";
    extension = pkgs.runCommand "cinnamon-extension-${uuid}" { } ''
        install -Dm444 ${./always-on-top/extension.js} "$out/share/cinnamon/extensions/${uuid}/extension.js"
        install -Dm444 ${./always-on-top/metadata.json} "$out/share/cinnamon/extensions/${uuid}/metadata.json"
    '';
in
{
    # Turning it on is org/cinnamon enabled-extensions in the dconf export beside this file
    environment.systemPackages = [ extension ];
}
