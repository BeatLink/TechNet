# Epiphany -- the phone's general-purpose browser.
#
# Thor has Butler for Home Assistant and Tangram for the other pinned sites, but
# nothing that opens an arbitrary URL since Firefox came off. Epiphany is the
# GTK4/WebKitGTK browser, which is the same engine both of those already run, so
# it adds a browser without adding a second engine to the closure.
#
{ pkgs, ... }:
{
    home-manager.users.beatlink = {
        home = {
            packages = [ pkgs.epiphany ];

            # Bookmarks, history, cookies and logins, across the rollback of /.
            persistence."/Storage/Apps/Core/Epiphany" = {
                directories = [
                    ".local/share/epiphany"
                    ".config/epiphany"
                ];
            };
        };
    };
}
