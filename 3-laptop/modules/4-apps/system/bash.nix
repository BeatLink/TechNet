{ config, pkgs, ... }: 
{
    environment.sessionVariables = {
        NIX_AUTO_RUN_INTERACTIVE = "true";
        NIX_AUTO_RUN = "true";
    };
    programs.bash = {
        shellAliases = {
            upgrade = "cd /Storage/TechNet && sudo nixos-rebuild --flake .# switch";
            purge = "sudo nix-collect-garbage -d";

            heimdall = "ssh heimdall.technet";
            odin = "ssh odin.technet";
            ragnarok = "ssh ragnarok.technet";

            l = "ls";
            la = "ls -la";
            lt = "tree -a";
        };
        completion.enable = true;
    };
    home-manager.users.beatlink = { config, pkgs, ... }: {
        programs.bash =  {
            historyControl = ["ignoreboth"];
            historyFile = ".local/share/bash/history";
        };
        home = {
            persistence."/Storage/Apps/System/Bash" = {
                directories = [
                    ".local/share/bash"
                ];
                allowOther = true;
            };
        };
    };
}