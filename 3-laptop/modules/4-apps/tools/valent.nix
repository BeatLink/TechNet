{ config, pkgs, ... }: 
{
    services.flatpak.packages = ["flathub:app/ca.andyholmes.Valent//stable"];
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home.file = {
            ".config/autostart/ca.andyholmes.Valent.desktop".text = ''
                [Desktop Entry]
                Type=Application
                Name=ca.andyholmes.Valent
                Exec=flatpak run --command=valent ca.andyholmes.Valent --gapplication-service
                X-Flatpak=ca.andyholmes.Valent
            '';
        };
    };
}