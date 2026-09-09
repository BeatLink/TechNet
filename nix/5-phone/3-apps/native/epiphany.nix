# Epiphany -- GTK4/WebKitGTK, as a second engine to compare against Firefox.
#
# It runs rather than crashes only because of WEBKIT_DISABLE_COMPOSITING_MODE in 1-system/webkit.nix: GTK4
# gets no GL context on a GLES 2.0 Mali-400, so WebKit's UI-side backing store is never created and the
# window used to die the moment the web process entered accelerated compositing.
#
# That means it renders entirely on the CPU. webkit.nix measured the same engine under GTK3 with
# GDK_GL=gles at 0.39 cores against 1.52 for the software path, so the fast route on this device is a GTK3
# WebKit browser, not this one -- Epiphany is here to be compared, not because it is the quick option.
#
# The profile from its last installation is still on the card and carries over.
#
{ pkgs, ... }:
{
    home-manager.users.beatlink = {
        home = {
            packages = [ pkgs.epiphany ];

            # Bookmarks, history, cookies and logins, across the rollback of /
            persistence."/Storage/Apps/Core/Epiphany" = {
                directories = [
                    ".local/share/epiphany"
                    ".config/epiphany"
                ];
            };
        };
    };
}
