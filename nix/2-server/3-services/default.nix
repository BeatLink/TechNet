# Home Server Configuration
#
# TODO: Add Notes
#

{
    imports = [
        ./backups
        ./blockurl.nix

        ./fun-and-media


        ./mosquitto.nix

        ./qbittorrent.nix
        ./radicale.nix

        ./syncthing.nix
        ./traccar.nix
        ./trilium.nix
        ./trilium-sysadmin.nix
        ./home-automation
        ./monitoring
    ];
}
