{
    environment.sessionVariables = {
        NIX_AUTO_RUN_INTERACTIVE = "true";
        NIX_AUTO_RUN = "true";
    };
    programs.command-not-found.enable = true;

    home-manager.users.beatlink = { ... }: {
        programs.command-not-found.enable = true;
        programs.bash =  {
            enable = true;
            historyControl = ["ignoreboth"];
            historyFile = "/home/beatlink/.local/share/bash/history";
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

    home-manager.users.root = { ... }: {
        programs.bash =  {
            enable = true;
            historyControl = ["ignoreboth"];
            historyFile = "/root/.local/share/bash/history";
            shellAliases = {
                upgrade = "cd /Storage/TechNet && sudo nixos-rebuild --flake .# switch";
                purge = "sudo nix-collect-garbage -d";

                heimdall = "ssh heimdall.technet";
                odin = "ssh odin.technet";
                ragnarok = "ssh ragnarok.technet";

                l = "ls";
                ll = "ls -alF";
                la = "ls -la";
                lt = "tree -a";
            };            
        };
    };
}