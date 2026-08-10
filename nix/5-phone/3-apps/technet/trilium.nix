# Trilium
#
# Odin's desktop client rather than the web UI. Its wrapper sets nothing for
# Electron, which picks X11 when left alone and opens on Odin's own screen.
#
{
    technet.waypipe.apps.trilium = {
        title = "Trilium";
        host = "odin-waypipe";
        icon = ./trilium.png; # A copy, so the phone does not carry Electron in its closure for one PNG

        command = [ "trilium" ];

        environment.ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    };
}
