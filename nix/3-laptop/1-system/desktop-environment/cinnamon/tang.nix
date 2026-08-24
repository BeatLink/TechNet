# Tang Applet
#
# Panel toggle for Odin's tang key server, so the keys are served on demand rather than for the whole session.
# Installed into the system data directory like always-on-top, rather than ~/.local/share/cinnamon where the
# spices downloaded from the Cinnamon site live.
#
{ pkgs, ... }:
let
    uuid = "tang@technet";
    applet = pkgs.runCommand "cinnamon-applet-${uuid}" { } ''
        install -Dm444 ${./tang/applet.js} "$out/share/cinnamon/applets/${uuid}/applet.js"
        install -Dm444 ${./tang/metadata.json} "$out/share/cinnamon/applets/${uuid}/metadata.json"
    '';
in
{
    # Placing it on a panel is org/cinnamon enabled-applets in the dconf export beside this file
    environment.systemPackages = [ applet ];
}
