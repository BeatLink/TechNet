{ config, lib, pkgs, ... }:
{
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            packages = with pkgs; [
                keepassxc
            ];
            persistence."/Storage/Apps/Core/KeePassXC" = {
                directories = [
                    ".var/app/org.keepassxc.KeePassXC"
                ];
                allowOther = true;
            };
            file = {
                ".config/autostart/org.keepassxc.KeePassXC.desktop".source = config.lib.file.mkOutOfStoreSymlink "/var/lib/flatpak/exports/share/applications/org.keepassxc.KeePassXC.desktop";
            };
        };
    };
}