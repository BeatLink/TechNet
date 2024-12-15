{ config, lib, pkgs, ... }:
{
    environment.systemPackages = with pkgs; [ qdirstat ];
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/Tools/QDirStat" = {
                directories = [
                    ".config/QDirStat"
                ];
                allowOther = true;
            };
        };
    };
}
