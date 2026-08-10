# Trilium
#
# Odin's desktop client rather than Heimdall's web UI in a kiosk window. Its own
# Electron data dir is what makes it a second instance; its notes are a second
# copy synced to Heimdall, because two processes cannot share one document.db.
#
{
    technet.waypipe.apps.trilium = {
        title = "Trilium";
        host = "odin-waypipe";
        icon = ./trilium.png; # A copy, so the phone does not carry Electron in its closure for one PNG
        categories = [ "Office" ];

        command = [
            "trilium"
            # Trilium's wrapper ignores NIXOS_OZONE_WL, so the flags it would have added are spelled out here; the last two are what the phone's keyboard types through
            "--ozone-platform=wayland"
            "--enable-features=WaylandWindowDecorations"
            "--enable-wayland-ime=true"
            "--wayland-text-input-version=3"
        ];

        environment = {
            # Holds the single-instance lock, so Odin's running copy does not adopt the launch and draw the window on its own screen
            TRILIUM_ELECTRON_DATA_DIR = "/home/beatlink/.config/trilium-waypipe/Thor";
            TRILIUM_DATA_DIR = "/home/beatlink/.local/share/trilium-waypipe/Thor";
            TRILIUM_PORT = "37841"; # Odin's instance holds 37840, and the collision would exit this one
            TRILIUM_SYNC_SYNCSERVERHOST = "https://trilium.heimdall.technet";
        };
    };
}
