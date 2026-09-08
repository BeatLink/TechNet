# LibreOffice on Heimdall, displayed here over waypipe, opening on the Start Center.
#
# soffice locks its user installation and hands any further launch to the copy already holding it, so
# keeping that directory here rather than at the default means a second launch starts its own process
# instead of being handed to one whose waypipe session has already ended.
#
{
    technet.waypipe.apps.libreoffice-heimdall = {
        title = "LibreOffice (Heimdall)";
        host = "heimdall-waypipe";
        icon = ./libreoffice.png; # A copy, so the phone does not carry LibreOffice in its closure for one PNG
        categories = [
            "Office"
            "WordProcessor"
            "Spreadsheet"
        ];

        # A URL rather than a path, because soffice parses this argument as one
        command = [
            "soffice"
            "-env:UserInstallation=file:///Storage/PhoneApps/LibreOffice/Thor"
        ];

        environment = {
            SAL_USE_VCLPLUGIN = "gtk3"; # Otherwise VCL falls back to its own X11 backend, which draws nothing over waypipe
            GDK_BACKEND = "wayland"; # Pinned so the toolkit takes waypipe's display rather than probing for another
        };
    };
}
