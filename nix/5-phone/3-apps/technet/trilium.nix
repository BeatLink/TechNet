# Trilium
#
# Heimdall's web UI as a kiosk window rather than Odin's desktop client, whose
# single-instance lock hands the window to Odin's own screen. Kiosk profile,
# shared with the other dashboards -- see home-assistant.nix for why.
#
{
    technet.waypipe.apps.trilium = {
        title = "Trilium";
        host = "odin-waypipe";
        icon = ./trilium.png; # A copy, so the phone does not carry Electron in its closure for one PNG
        categories = [ "Office" ];

        command = [
            "firefox"
            "--profile"
            "/home/beatlink/.config/mozilla/firefox-waypipe/Kiosk-Thor"
            "--kiosk"
            "--new-window"
            "https://trilium.heimdall.technet"
        ];

        # Odin's GTK apps otherwise reach for its own session rather than waypipe's display
        environment.GDK_BACKEND = "wayland";
    };
}
