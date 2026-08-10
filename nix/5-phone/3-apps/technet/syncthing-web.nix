# Syncthing Web UI
#
# Firefox runs on Odin, so the address has to name this phone: localhost over
# there is Odin's own daemon. syncthing.thor.lan does not resolve off the LAN,
# so the WireGuard name is the one that always answers. Kiosk profile, shared
# with the other dashboard -- see home-assistant.nix for why.
#
{ pkgs, ... }:
{
    technet.waypipe.apps.syncthing-web = {
        title = "Syncthing Web UI";
        host = "odin-waypipe";
        icon = "${pkgs.syncthing}/share/icons/hicolor/scalable/apps/syncthing.svg";
        categories = [
            "Network"
            "FileTransfer"
            "P2P"
        ];

        command = [
            "firefox"
            "--profile"
            "/home/beatlink/.config/mozilla/firefox-waypipe/Kiosk-Thor"
            "--kiosk"
            "--new-window"
            "http://thor.technet:8384"
        ];

        # Odin's GTK apps otherwise reach for its own session rather than waypipe's display
        environment.GDK_BACKEND = "wayland";
    };
}
