
{ config, pkgs, ... }: 
{
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            packages = with pkgs; [ deluge ];
            persistence."/Storage/Apps/Tools/Deluge" = {
                directories = [
                    ".config/deluge"
                ];
                allowOther = true;
            };
            file.".config/autostart/deluge.desktop".source = "${pkgs.deluge}/share/applications/deluge.desktop";
        };
    };
}