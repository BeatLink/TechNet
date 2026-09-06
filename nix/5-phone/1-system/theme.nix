# Mint-Y-Aqua, on the parts of the phone that can take a GTK theme.
#
# Worth knowing what this does and does not reach. phosh is GTK3, so the shell
# itself follows this -- the top bar, the lock screen, the app grid. GTK3
# applications follow it too.
#
# GTK4 applications ignore gtk-theme-name outright, so home-manager instead
# writes a gtk-4.0/gtk.css that @imports Mint-Y's own gtk-4.0 stylesheet as user
# CSS. That reaches plain GTK4 widgets; libadwaita apps such as Files, Settings
# and Secrets still draw most of their own styling and stay close to Adwaita.
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

            gtk4.theme = {
                name = "Mint-Y-Aqua"; # Pinned, not inherited: home-manager's gtk4 default becomes null at stateVersion 26.05
                package = pkgs.mint-themes;
            };

            iconTheme = {
                name = "Mint-Y-Aqua";
                package = pkgs.mint-y-icons;
            };
        };

        # Deliberately not persisted. Persisting .config/gtk-3.0 bind-mounts an
        # empty directory over the settings.ini home-manager generates, so the
        # theme silently does not apply -- which is exactly what happened the
        # first time this was written.
        #
        # The two cannot both be true: either this file is declared here and a
        # rebuild restores it, or it is runtime state and the config does not
        # own it. Declared wins, so changing theme means changing this.
    };
}
