{
        home-manager.users.beatlink = {
        home.file = {
            ".local/share/icons/timestretch.png".source = ./timestretch.png;
            ".local/share/applications/TimeStretch.desktop".text = ''
                [Desktop Entry]
                Name=TimeStretch Player
                Exec=firefox https://29a.ch/timestretch/
                Comment=
                Terminal=false
                PrefersNonDefaultGPU=false
                Icon=timestretch.png
                Type=Application
                Categories=Sound & Video
            '';
        };
    };
}