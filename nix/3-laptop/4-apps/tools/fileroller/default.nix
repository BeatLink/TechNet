{
    home-manager.users.beatlink = {
        dconfImports = {
            org-gnome-fileroller = {
                source = ./2-dconf-settings.ini;
                path = "/org/gnome/file-roller/";
            };
        };
    };
}
