{
    home-manager.users.beatlink = {
        home.file = {
            ".local/share/icons/calibre-web.png".source = ./calibre-web.png;

            ".local/share/applications/calibre-web.desktop".text = ''
                [Desktop Entry]
                Name=Calibre Web
                Exec=firefox https://calibre-web.heimdall.technet
                Comment=
                Terminal=false
                PrefersNonDefaultGPU=false
                Icon=calibre-web.png
                Categories=Office
                Type=Application
            '';
        };
    };
}
