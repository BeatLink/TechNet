{ config, pkgs, ... }: 
{
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            packages = with pkgs; [ ckan ];
        };
    };
};