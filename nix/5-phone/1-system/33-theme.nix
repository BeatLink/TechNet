# Mint-Y-Aqua, on the parts of the phone that can take a GTK theme.
#
# Worth knowing what this does and does not reach. phosh is GTK3, so the shell
# itself follows this -- the top bar, the lock screen, the app grid. GTK3
# applications follow it too.
#
# GTK4 applications do not. libadwaita draws its own styling and deliberately
# ignores the GTK theme, so Epiphany, Files, Settings and Secrets stay Adwaita
# whatever is set here. Mint-Y ships gtk-3.0, cinnamon and gnome-shell
# stylesheets and no gtk-4.0 one, so there is nothing for them to pick up even
# if they looked.
#
# Set through home-manager rather than dconf directly, so gtk-3.0/settings.ini
# is written as well as the dconf key -- applications started outside the
# session read the file rather than the database.
{ pkgs, ... }:
{
    home-manager.users.beatlink = {
        gtk = {
            enable = true;

            theme = {
                name = "Mint-Y-Aqua";
                package = pkgs.mint-themes;
            };

            iconTheme = {
                name = "Mint-Y-Aqua";
                package = pkgs.mint-y-icons;
            };
        };

        # The theme is a preference rather than a fixed part of the system, so
        # it is persisted and can be changed from Settings without a rebuild
        # putting it back.
        home.persistence."/Storage/Apps/System/Theme".directories = [
            ".config/gtk-3.0"
            ".config/gtk-4.0"
        ];
    };
}
