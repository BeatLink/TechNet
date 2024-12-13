{ config, lib, pkgs, ... }:
{
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home.file = {
            ".local/share/icons/home-assistant.png".source = ./home-assistant.png;

            ".local/share/applications/home-assistant.desktop".text = ''
                [Desktop Entry]
                Name=Home Assistant
                Exec=flatpak run org.mozilla.firefox https://homeassistant.heimdall.technet
                Comment=
                Terminal=false
                PrefersNonDefaultGPU=false
                Icon=home-assistant.png
                Type=Application
            '';

            ".config/plank/dock1/launchers/home-assistant.dockitem".text = ''
                [PlankDockItemPreferences]
                Launcher=file:///home/beatlink/.local/share/applications/home-assistant.desktop
            '';

        };
    };
}