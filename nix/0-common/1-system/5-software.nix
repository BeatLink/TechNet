# Software
#
# Configures Software in NixOS
#   - Enables Flakes
#   - Enables Automatic System Upgrades
#   - Enables Garbage Collection
#   - Enables Unfree Packages
#   - Removes default Apps
#

{
    pkgs,
    config,
    lib,
    inputs,
    ...
}:
{

    # Enable Flakes
    nix = {
        extraOptions = ''experimental-features = nix-command flakes''; # Enables Flakes
        registry.nixpkgs.flake = inputs.nixpkgs;
        nixPath = [ "nixpkgs=${inputs.nixpkgs.outPath}" ]; # Configures nix to use nixpkgs from flakes, fixes pesky errors in nix-shell
    };

    # Enables Automatic Upgrades
    system.autoUpgrade = {
        # Configures Automatic Upgrades at 2AM from my GitHub flake.
        enable = true;
        flake = "github:BeatLink/TechNet";
        operation = "switch";
        flags = [
            "--no-write-lock-file"
            "-L"
        ];
        dates = "02:00";
        allowReboot = false;
        persistent = true;
    };
    systemd.services.nixos-upgrade =
        let
            # Sends status updates to Uptime Kuma on Heimdall
            BaseURL = "https://uptime-kuma.heimdall.technet/api/push/";
            Keys = {
                Ragnarok = "sTgpl4hkEc";
                Odin = "Iy9Tfr31nG";
                Heimdall = "urMFRtdrYA";
            };
            FullURL = "${BaseURL}${Keys.${config.networking.hostName}}";
        in
        {
            postStop = ''
                if [ "$SERVICE_RESULT" == "success" ]; then
                    ${pkgs.wget}/bin/wget --spider --no-check-certificate "${FullURL}?status=up&msg=$(date '+%Y-%m-%d %H:%M:%S') System Upgrades Successful&ping=";
                else
                    ${pkgs.wget}/bin/wget --spider --no-check-certificate "${FullURL}?status=down&msg=$(date '+%Y-%m-%d %H:%M:%S') System Upgrades Failed&ping=";
                fi        
            '';
        };

    # Enable Garbage Collection
    nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
    };

    # Enables Unfree Packages
    nixpkgs.config.allowUnfree = true;

    # Removes Default Packages
    environment.defaultPackages = lib.mkForce [ ];
}
