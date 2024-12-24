# Software ################################################################################################################################
#
# Enables flakes, allows unfree packages, enables auto upgrades and install default software                                                
#
###########################################################################################################################################

{ config, lib, pkgs, modulesPath, ... }: 
{
    nix = {                                                             # Enables Flakes
        extraOptions = ''experimental-features = nix-command flakes'';
        settings.trusted-users = [ "root" "beatlink" ];                 # Allows me to remote update by sending the flake over ssh
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
    systemd.extraConfig = "DefaultLimitNOFILE=65536";                  # Increase number of open files (Steam, syncthing, etc)

    environment = {
        defaultPackages = lib.mkForce [];
        systemPackages = with pkgs; [                                   # Set packages installed on system
            wget                                                        # For downloading stuff
            htop                                                        # For checking the system status
            ncdu                                                        # For checking disk usage
            git                                                         # For downloading git repos
            nano
            tree                                                        # For editing config files
            curl
            iputils
            sops
            pciutils
            usbutils 
        ];
    };

}