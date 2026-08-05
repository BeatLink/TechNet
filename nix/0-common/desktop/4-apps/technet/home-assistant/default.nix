{
    home-manager.users.beatlink = {
        home.file = {
            ".local/share/icons/home-assistant.png".source = ./home-assistant.png;

            ".local/share/applications/home-assistant.desktop".text = ''
                [Desktop Entry]
                Name=Home Assistant
                Exec=firefox --kiosk https://home-assistant.heimdall.technet
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
