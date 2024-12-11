{ config, lib, pkgs, ... }:
{
    services.flatpak = {
        packages = ["flathub:app/com.vscodium.codium//stable"];
        overrides."com.vscodium.codium" = {
            filesystems = [
                "~/.config/git:ro"
            ];
        };
    };
    programs.fuse.userAllowOther = true;
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home.persistence."/Storage/Apps/Programming/VsCodium" = {
            directories = [
                ".var/app/com.vscodium.codium"
                ".vscode-oss"
            ];
            allowOther = true;
        };
    };
}