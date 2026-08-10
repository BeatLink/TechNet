# Software
#
# Configures software in NixOS: flakes, automatic upgrades, garbage collection, unfree packages and the PinePhone kernel cache.
{
    config,
    lib,
    inputs,
    ...
}:
{
    imports = [ inputs.nixtool.nixosModules.default ];

    # PinePhone Kernel Binary Cache ##################################################################################################################
    # Opt-in, not network-wide: only Thor runs megi's kernel and only Odin builds Thor's closure.
    # Elsewhere the substituter is queried for every path it will never hold, and GitHub Pages answers those bulk narinfo lookups with HTTP 429.
    options.technet.pinephoneCache.enable = lib.mkEnableOption "the PinePhone kernel binary cache";

    config = lib.mkMerge [
        # Called rather than imported, because `imports` cannot be placed behind mkIf; this keeps the URL and key from drifting out of the input
        (lib.mkIf config.technet.pinephoneCache.enable (inputs.pinephone-kernel.nixosModules.binaryCache { }))

        {
            # Enable Flakes ##########################################################################################################################
            # Owned, not root-only: flake fetching runs as the user, and `!include` swallows the permission error
            sops.secrets.github_access_token_conf = {
                sopsFile = "${config.technet.secrets.commonPath}/github.yaml";
                owner = "beatlink";
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

            # Enables Automatic Upgrades #############################################################################################################
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

            # Enable Garbage Collection ##############################################################################################################
            nix.gc = {
                automatic = true;
                dates = "weekly";
                options = "--delete-older-than 7d";
            };

            # Enables Unfree Packages ################################################################################################################
            nixpkgs.config.allowUnfree = true;

            # Removes Default Packages ###############################################################################################################
            environment.defaultPackages = lib.mkForce [ ];
        }
    ];
}
