# Terminal ###########################################################################################################################################
#
# The interactive shell for beatlink and root, plus the command line tools every host carries.
#

{
    config,
    lib,
    pkgs,
    ...
}:
let
    # Persists one of root's data directories, unreadable by anyone else at its source path under /persistent.
    rootState = directory: {
        inherit directory;
        user = "root";
        group = "root";
        mode = "0700";
    };

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

    atuinClient = {
        enable = true;
        forceOverwriteSettings = true;
        flags = [ "--disable-up-arrow" ];
        settings = {
            auto_sync = true;
            sync_address = "https://atuin.heimdall.technet";
            sync_frequency = "5m";
            update_check = false;
        };
    };

    # Claims this host's shell for the shared history account, once per user per install.
    atuinLogin = user: {
        description = "Log ${user} in to the TechNet shell history server";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        path = [ pkgs.atuin ];
        script = ''
            # Atuin keeps the session in meta.db, not a session file, so its exit code is the only login check
            if atuin status >/dev/null 2>&1; then exit 0; fi
            atuin login --username "$ATUIN_USERNAME" --password "$ATUIN_PASSWORD" --key "$ATUIN_KEY"
        '';
        serviceConfig = {
            Type = "oneshot";
            User = user;
            RemainAfterExit = true;
            EnvironmentFile = config.sops.secrets.atuin_login.path;
            Restart = "on-failure"; # Allowed for oneshot, unlike always, and the only retry a host that booted off-network gets
            RestartSec = 60;
        };
    };
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

            environment.persistence."/persistent".directories = [ (rootState "/root/.local/share/bash") ];
        }

        # Shell History Sync #########################################################################################################################
        {
            sops.secrets.atuin_login = {
                sopsFile = "${config.technet.secrets.commonPath}/atuin.yaml";
                owner = "beatlink";
            };

            home-manager.users.beatlink = {
                programs.atuin = atuinClient;
                home.persistence."/Storage/Apps/System/Atuin".directories = [ ".local/share/atuin" ];
            };

            home-manager.users.root.programs.atuin = atuinClient;
            environment.persistence."/persistent".directories = [ (rootState "/root/.local/share/atuin") ];

            systemd.services = {
                atuin-login-beatlink = atuinLogin "beatlink";
                atuin-login-root = atuinLogin "root";
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
