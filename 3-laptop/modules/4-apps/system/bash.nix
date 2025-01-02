{ config, pkgs, ... }: 
{
    environment.systemPackages = with pkgs; [ comma ];
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
        shellInit = ''
            export NIX_AUTO_RUN_INTERACTIVE=true
            NIX_AUTO_RUN=true;
        '';
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