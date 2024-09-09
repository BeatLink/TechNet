# Software ----------------------------------------------------------------------------------------------------------------------------
{ config, lib, pkgs, modulesPath, ... }: 
{
    nixpkgs.config.allowUnfree = true;                                  # Allow unfree packages
    environment.systemPackages = with pkgs; [                           # Set packages installed on system
        wget                                                            # For downloading stuff
        curl                                                            # Also for downloading stuff
        htop                                                            # For checking the system status
        ncdu                                                            # For checking disk usage
        git                                                             # For downloading git repos
        nano                                                            # For editing config files
    ];

}