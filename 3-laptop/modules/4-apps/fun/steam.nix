{ config, pkgs, ... }: 
{
    programs.steam = {
        enable = true;
        remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
        dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
        localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    };
    environment.systemPackages = with pkgs; [mangohud protonup-qt lutris heroic];

    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/Fun/Steam" = {
                directories = [
                    ".local/share/Steam"
                ];
                allowOther = true;
            };
        };
    };
}
