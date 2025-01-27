{ config, lib, pkgs, ... }:
{
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            packages = with pkgs; [ baobab ];
            persistence."/Storage/Apps/System/Baobab" = {
                allowOther = true;
            };
        };
    };
}
