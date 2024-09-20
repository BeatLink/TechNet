# Software ----------------------------------------------------------------------------------------------------------------------------
{ config, lib, pkgs, modulesPath, ... }: 
{
    nix = {                                                             # Enables Flakes
        package = pkgs.nixFlakes;
        extraOptions = ''experimental-features = nix-command flakes'';
        settings.trusted-users = [ "root" "beatlink" ];                 # Allows me to remote update by sending the flake over ssh
    };
    nixpkgs.config.allowUnfree = true;                                  # Allow unfree packages
    system.autoUpgrade = {
        enable = true;
        allowReboot = true;
    };
    environment.systemPackages = with pkgs; [                           # Set packages installed on system
        wget                                                            # For downloading stuff
        curl                                                            # Also for downloading stuff
        htop                                                            # For checking the system status
        ncdu                                                            # For checking disk usage
        git                                                             # For downloading git repos
        nano                                                            # For editing config files
    ];

}