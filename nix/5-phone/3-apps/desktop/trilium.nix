# Trilium
#
# Heimdall's desktop client rather than its web UI in a kiosk window. Its own
# Electron data dir holds the single-instance lock, and its notes are a second
# copy synced to the server on the same host, because two processes cannot
# share one document.db.
#
{
    technet.waypipe.apps.trilium = {
        title = "Trilium";
        host = "heimdall-waypipe";
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
            # Holds the single-instance lock, so a launch is not handed to a copy whose waypipe session has already ended
            TRILIUM_ELECTRON_DATA_DIR = "/Storage/PhoneApps/Trilium/Thor/electron";
            TRILIUM_DATA_DIR = "/Storage/PhoneApps/Trilium/Thor/data";
            TRILIUM_SYNC_SYNCSERVERHOST = "https://trilium.heimdall.technet";
        };
    };
}
