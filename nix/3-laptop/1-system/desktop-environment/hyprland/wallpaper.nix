# Wallpaper
#
# hyprpaper handles the desktop wallpaper. Variety (configured in 4-apps/system/variety.nix) writes the current
# wallpaper to ~/.config/variety/wallpaper/wallpaper.jpg, so that path is used as the source here.
#

{
    home-manager.users.beatlink =
        { config, ... }:
        {
            services.hyprpaper = {
                enable = true;
                settings = {
                    ipc = "on";
                    splash = false;
                    preload = [ "${config.home.homeDirectory}/.config/variety/wallpaper/wallpaper.jpg" ];
                    wallpaper = [ ",${config.home.homeDirectory}/.config/variety/wallpaper/wallpaper.jpg" ];
                };
            };
        };
}
