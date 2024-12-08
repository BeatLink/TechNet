# Laptop Configuration ###############################################################################################################
# TODO: Add Notes
###########################################################################################################################################

{ config, lib, pkgs, ... }:
{
    environment.systemPackages = [
        pkgs.plank
    ];
    home-manager.users.beatlink = {
        dconf.enable = true;
        imports = [
            ./2-dconf-settings.nix
        ];
    };
}
