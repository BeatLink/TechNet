{ pkgs, ... }:
{
    programs = {
        steam = {
            enable = true;
            remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
            dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
            localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
            gamescopeSession.enable = true;
        };
        gamemode.enable = true;
    };

    environment.systemPackages = with pkgs; [
        protonup-qt
    ];

    home-manager.users.beatlink = {
        home = {
            persistence."/Storage/Apps/Fun/Steam" = {
                directories = [
                    ".local/share/Steam"
                ];

            };
        };
    };
}
