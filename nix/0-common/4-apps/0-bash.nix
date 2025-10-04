{
    environment.sessionVariables = {
        NIX_AUTO_RUN_INTERACTIVE = "true";
        NIX_AUTO_RUN = "true";
    };

    home-manager.users.beatlink = {
        programs.bash =  {
            enable = true;
            historyControl = ["ignoreboth"];
            historyFile = "/home/beatlink/.local/share/bash/history";
            shellAliases = {
                nixos-purge = "sudo nix-collect-garbage -d";
                nixos-upgrade = "sudo systemctl start nixos-upgrade & journalctl -fu nixos-upgrade";
                nixos-upgrade-local = "cd /Storage/TechNet && sudo nixos-rebuild --flake .# switch";

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