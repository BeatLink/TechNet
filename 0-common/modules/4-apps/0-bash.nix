{
    environment.sessionVariables = {
        NIX_AUTO_RUN_INTERACTIVE = "true";
        NIX_AUTO_RUN = "true";
    };

    home-manager.users.beatlink = { ... }: {
        programs.bash =  {
            enable = true;
            historyControl = ["ignoreboth"];
            historyFile = ".local/share/bash/history";
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
            
        };
    };
}