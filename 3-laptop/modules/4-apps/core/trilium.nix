{ config, lib, pkgs, ... }:
{
    services.flatpak.packages = ["flathub:app/com.github.zadam.trilium//stable"];
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/Core/Trilium" = {
                directories = [
                    ".var/app/com.github.zadam.trilium"
                ];
                allowOther = true;
            };
            # file.".config/autostart/org.keepassxc.KeePassXC".source = config.lib.file.mkOutOfStoreSymlink "/var/lib/flatpak/app/org.keepassxc.KeePassXC/current/active/files/share/applications/org.keepassxc.KeePassXC.desktop";
        };
    };
}