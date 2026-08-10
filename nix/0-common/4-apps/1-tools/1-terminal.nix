# Terminal ###########################################################################################################################################
#
# The interactive shell for beatlink and root, plus the command line tools every host carries.
#

{ lib, pkgs, ... }:
let
    powerlineModules = [
        "user"
        "host"
        "cwd"
        "perms"
        "ssh"
        "git"
        "venv"
        "nix-shell"
        "exit"
        "jobs"
        "root"
    ];
in
{
    config = lib.mkMerge [

        # Nix Auto Run ###############################################################################################################################
        {
            environment.sessionVariables = {
                NIX_AUTO_RUN_INTERACTIVE = "true";
                NIX_AUTO_RUN = "true";
            };
        }

        # Bash History ###############################################################################################################################
        {
            home-manager.users.beatlink = {
                programs.bash = {
                    enable = true;
                    historyControl = [ "ignoreboth" ];
                    historyFile = "/home/beatlink/.local/share/bash/history";
                };

                home.persistence."/Storage/Apps/System/Bash".directories = [ ".local/share/bash" ];
            };

            home-manager.users.root.programs.bash = {
                enable = true;
                historyControl = [ "ignoreboth" ];
                historyFile = "/root/.local/share/bash/history";
            };
        }

        # Shell Aliases ##############################################################################################################################
        {
            home-manager.users.beatlink.programs.bash.shellAliases = {
                nixos-purge = "sudo nix-collect-garbage -d";
                nixos-upgrade = "sudo systemctl start nixos-upgrade & journalctl -fu nixos-upgrade";
                nixos-upgrade-local = "cd /Storage/TechNet && sudo nixos-rebuild --flake .# switch";

                heimdall = "ssh heimdall.technet";
                odin = "ssh odin.technet";
                ragnarok = "ssh ragnarok.technet";
                thor = "ssh thor.technet";

                l = "ls";
                la = "ls -la";
                lt = "tree -a";

                pyclean = "find . -type d -name __pycache__ -prune -exec rm -rf {} +";
            };

            home-manager.users.root.programs.bash.shellAliases = {
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
        }

        # Powerline Prompt ###########################################################################################################################
        {
            home-manager.users.beatlink.programs.powerline-go = {
                enable = true;
                modules = powerlineModules;
            };

            home-manager.users.root.programs.powerline-go = {
                enable = true;
                modules = powerlineModules;
            };
        }

        # Text Editor ################################################################################################################################
        {
            environment.systemPackages = [ pkgs.nano ];
        }

        # File and Disk Browsing #####################################################################################################################
        {
            environment.systemPackages = with pkgs; [
                ncdu
                tree
            ];
        }

        # System Inspection ##########################################################################################################################
        {
            environment.systemPackages = with pkgs; [
                fastfetch
                htop
                iputils
                pciutils
                smartmontools
                usbutils
            ];
        }

        # Download Management ########################################################################################################################
        {
            environment.systemPackages = with pkgs; [
                curl
                wget
            ];
        }
    ];
}
