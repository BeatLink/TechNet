{ config, lib, pkgs, ... }:
{
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/TechNet/KDEConnect/" = {
                directories = [
                    ".config/kdeconnect/"
                ];
                allowOther = true;
            };
        };
    };
}
