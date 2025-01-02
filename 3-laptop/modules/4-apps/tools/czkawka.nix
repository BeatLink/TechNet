{ config, pkgs, ... }: 
{
    environment.systemPackages = with pkgs; [ czkawka ];
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/Tools/Czkawka" = {
                directories = [
                    ".cache/czkawka"
                    ".config/czkawka"
                ];
                allowOther = true;
            };
        };
    };
}

