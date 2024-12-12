{ config, lib, pkgs, ... }:
{
    services.flatpak.packages = ["flathub:app/org.keepassxc.KeePassXC//stable"];
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/Core/KeePassXC" = {
                directories = [
                    ".var/app/org.keepassxc.KeePassXC"
                ];
                allowOther = true;
            };
            file = {
                ".config/autostart/org.keepassxc.KeePassXC".source = config.lib.file.mkOutOfStoreSymlink "/var/lib/flatpak/app/org.keepassxc.KeePassXC/current/active/files/share/applications/org.keepassxc.KeePassXC.desktop";
                
                ".config/plank/dock1/launchers/org.keepassxc.KeePassXC.dockitem".text = ''
                    [PlankDockItemPreferences]
                    Launcher=file:///var/lib/flatpak/exports/share/applications/org.keepassxc.KeePassXC.desktop
                '';
            };
        };
    };
}