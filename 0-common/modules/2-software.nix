# Software ################################################################################################################################
#
# Enables flakes, allows unfree packages, enables auto upgrades and install default software                                                
#
###########################################################################################################################################

{ config, lib, pkgs, modulesPath, ... }: 
{
    nix = {                                                             # Enables Flakes
        package = pkgs.nixFlakes;
        extraOptions = ''experimental-features = nix-command flakes'';
        settings.trusted-users = [ "root" "beatlink" ];                 # Allows me to remote update by sending the flake over ssh
        allowedUsers = [ "@wheel" ];
        gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 7d";
        };


    };
    nixpkgs.config.allowUnfree = true;                                  # Allow unfree packages
    system.autoUpgrade = {
        enable = true;
        allowReboot = true;
        flake = "github:BeatLink/TechNet";
        flags = [
            "--no-write-lock-file"
            "-L"
        ];
        dates = "02:00";
        randomizedDelaySec = "45min";
    };

    environment = {
        defaultPackages = lib.mkForce [];
        systemPackages = with pkgs; [                           # Set packages installed on system
            wget                                                            # For downloading stuff
            curl                                                            # Also for downloading stuff
            htop                                                            # For checking the system status
            ncdu                                                            # For checking disk usage
            git                                                             # For downloading git repos
            nano                                                            # For editing config files
        ];
    };

}