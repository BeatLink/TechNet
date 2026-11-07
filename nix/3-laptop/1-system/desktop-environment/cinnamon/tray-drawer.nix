# Tray Drawer
#
# Our tray applet: one tray for XApp, StatusNotifier and XEmbed icons that tucks chosen icons and applets into a drawer.
# It does the stock System Tray and XApp Status applets' jobs, so those two are removed from Cinnamon.
#
{ inputs, pkgs, ... }:
let
    uuid = "tray-drawer@beatlink";
    applet = pkgs.runCommand "cinnamon-applet-${uuid}" { } ''
        mkdir -p "$out/share/cinnamon/applets"
        cp -r ${inputs.tray-drawer}/${uuid}/files/${uuid} "$out/share/cinnamon/applets/${uuid}"
    '';
in
{
    # Placing it on a panel is org/cinnamon enabled-applets in the dconf export beside this file
    environment.systemPackages = [ applet ];

    nixpkgs.overlays = [
        (final: prev: {
            cinnamon = prev.cinnamon.overrideAttrs (old: {
                # Both would take the tray icons away from this applet if added to a panel
                postInstall = (old.postInstall or "") + ''
                    rm -r "$out/share/cinnamon/applets/systray@cinnamon.org" "$out/share/cinnamon/applets/xapp-status@cinnamon.org"
                '';
            });
        })
    ];
}
