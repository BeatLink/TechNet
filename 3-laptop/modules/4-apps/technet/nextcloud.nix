{ config, lib, pkgs, ... }:
{
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home.file = {
            ".local/share/applications/nextcloud.desktop".text = ''
                [Desktop Entry]
                Name=Nextcloud
                Exec=flatpak run org.mozilla.firefox https://nextcloud.heimdall.technet
                Comment=
                Terminal=false
                PrefersNonDefaultGPU=false
                Icon=goa-account-owncloud
                Type=Application
                Categories=Network
            '';

            ".config/plank/dock1/launchers/nextcloud.dockitem".text = ''
                [PlankDockItemPreferences]
                Launcher=file:///home/beatlink/.local/share/applications/nextcloud.desktop
            '';
        };
    };
}