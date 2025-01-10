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
                Categories=Network
                Type=Application
            '';
        };
    };
}