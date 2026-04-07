# Home Server Configuration
#
# TODO: Add Notes
#

{
    imports = [
        ./mosquitto.nix
        ./qbittorrent.nix
        ./traccar.nix
        ./backups
        ./fun-and-media
        ./home-automation
        ./monitoring
        ./networking
        ./personal-info-and-files
    ];
}
