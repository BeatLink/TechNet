# LibreOffice on Odin, displayed here over waypipe, opening on the Start Center.
#
# Its own user installation is what makes it a second process: soffice locks that directory and
# hands any further launch to the copy already holding it, which would draw on Odin's screen.
#
{
    technet.waypipe.apps.libreoffice-odin = {
        title = "LibreOffice (Odin)";
        host = "odin-waypipe";
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
            SAL_USE_VCLPLUGIN = "gtk3"; # Otherwise VCL falls back to its own X11 backend when it finds no session of Odin's to join
            GDK_BACKEND = "wayland"; # Odin's GTK apps otherwise reach for its own session rather than waypipe's display
        };
    };
}
