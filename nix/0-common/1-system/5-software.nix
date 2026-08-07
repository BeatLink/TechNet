# Software
#
# Configures software in NixOS: flakes, automatic upgrades, garbage collection and unfree packages.
{
    config,
    lib,
    inputs,
    ...
}:
{
    imports = [ inputs.nixtool.nixosModules.default ];

    # Enable Flakes ##############################################################################################################################
    sops.secrets.github_access_token_conf = {
        sopsFile = "${config.technet.secrets.commonPath}/github.yaml";
    };

    nix = {
        extraOptions = ''
            experimental-features = nix-command flakes
            !include ${config.sops.secrets.github_access_token_conf.path}
        '';
        registry.nixpkgs.flake = inputs.nixpkgs;
        nixPath = [ "nixpkgs=${inputs.nixpkgs.outPath}" ]; # Configures nix to use nixpkgs from flakes, fixes pesky errors in nix-shell
    };
    programs.command-not-found.enable = false;
    home-manager.users.beatlink = {
        programs.command-not-found.enable = false;
    };

    # Enables Automatic Upgrades #################################################################################################################
    system.autoUpgrade = {
        # Configures Automatic Upgrades at 2AM from my GitHub flake.
        enable = true;
        flake = "github:BeatLink/TechNet";
        operation = "switch";
        flags = [
            "--no-write-lock-file"
            "-L"
        ];
        dates = lib.mkDefault "Sat 08:00";
        allowReboot = true;
        persistent = true;
    };
    systemd.services.nixos-upgrade = {
        postStop = ''
            if [ "$SERVICE_RESULT" == "success" ]; then
                echo "System upgrade successful at $(date '+%Y-%m-%d %H:%M:%S')"
            else
                echo "System upgrade failed at $(date '+%Y-%m-%d %H:%M:%S') with result: $SERVICE_RESULT"
            fi
        '';
    };

    # Enable Garbage Collection ##################################################################################################################
    nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
    };

    # Enables Unfree Packages ####################################################################################################################
    nixpkgs.config.allowUnfree = true;

    # Removes Default Packages ###################################################################################################################
    environment.defaultPackages = lib.mkForce [ ];
}
