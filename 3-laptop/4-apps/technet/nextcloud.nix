{
    home-manager.users.beatlink = {
        home.file = {
            ".local/share/applications/nextcloud.desktop".text = ''
                [Desktop Entry]
                Name=Nextcloud
                Exec=firefox https://nextcloud.heimdall.technet
                Comment=
                Terminal=false
                PrefersNonDefaultGPU=false
                Icon=goa-account-owncloud
                Type=Application
                Categories=Network
            '';
        };
    };
}