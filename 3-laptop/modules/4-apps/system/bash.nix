{ config, pkgs, ... }: 
{
    programs.bash = {
        shellAliases = {
            update = "cd /Storage/TechNet && sudo nixos-rebuild --flake .# switch";
        };
    };
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/System/Bash" = {
                directories = [
                ];
                allowOther = true;
            };
        };
    };
}