{ config, pkgs, ... }:
{
    environment.systemPackages = [
        pkgs.dconf-editor
    ];
    system.stateVersion = "24.05"; # Did you read the comment?
}
