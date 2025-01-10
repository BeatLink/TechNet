{ config, lib, pkgs, ... }:
{
    environment.systemPackages = with pkgs; [ nixd nixfmt-rfc-style ];
    services.flatpak = {
        packages = ["flathub:app/com.vscodium.codium//stable"];
        overrides."com.vscodium.codium" = {
            filesystems = [
                "/home/beatlink/.config/git:ro"
                "host"
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
        };
    };
}