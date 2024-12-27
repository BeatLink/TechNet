{ config, pkgs, ... }: 
{
    programs.bash = {
        shellAliases = {
            upgrade = "cd /Storage/TechNet && sudo nixos-rebuild --flake .# switch";
            heimdall = "ssh heimdall.technet";
            odin = "ssh odin.technet";
            ragnarok = "ssh ragnarok.technet";

            l = "ls";
            la = "ls -la";
            lt = "tree -a";
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