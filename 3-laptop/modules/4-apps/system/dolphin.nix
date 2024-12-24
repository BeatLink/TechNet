
{ config, lib, pkgs, ... }:

{
    environment.systemPackages = with pkgs; [ dolphin ];
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/System/Dolphin" = {
                directories = [
                    ".local/share/dolphin"
                ];
                files = [
                    ".config/dolphinrc"
                ];
                allowOther = true;
            };
        };
    };
}