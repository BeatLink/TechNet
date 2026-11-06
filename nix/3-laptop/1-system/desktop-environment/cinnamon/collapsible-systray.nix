# Collapsible System Tray
#
# Our tray applet: one tray for XApp, StatusNotifier and XEmbed icons that tucks chosen icons and applets into a drawer or popup grid.
# It does the stock System Tray and XApp Status applets' jobs, so those two stay off the panel.
#
{ inputs, pkgs, ... }:
let
    uuid = "collapsible-systray@beatlink";
    applet = pkgs.runCommand "cinnamon-applet-${uuid}" { } ''
        mkdir -p "$out/share/cinnamon/applets"
        cp -r ${inputs.collapsible-systray}/${uuid}/files/${uuid} "$out/share/cinnamon/applets/${uuid}"
    '';
in
{
    # Placing it on a panel is org/cinnamon enabled-applets in the dconf export beside this file
    environment.systemPackages = [ applet ];
}
