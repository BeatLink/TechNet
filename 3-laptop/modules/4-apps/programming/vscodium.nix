{ config, lib, pkgs, ... }:
{
    services.flatpak = {
        packages = ["flathub:app/com.vscodium.codium//stable"];
        overrides."com.vscodium.codium" = {
            filesystems = [
                "/home/beatlink/.config/git:ro"
            ];
        };
    };
    programs.fuse.userAllowOther = true;
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/Programming/VsCodium" = {
                directories = [
                    ".var/app/com.vscodium.codium"
                    ".vscode-oss"
                ];
                allowOther = true;
            };
            file = {
                ".config/plank/dock1/launchers/com.vscodium.codium.dockitem".text = ''
                    [PlankDockItemPreferences]
                    Launcher=file:///var/lib/flatpak/exports/share/applications/com.vscodium.codium.desktop
                '';
            };
        };
    };
}