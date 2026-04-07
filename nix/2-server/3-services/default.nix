# Home Server Configuration
#
# TODO: Add Notes
#

{
    imports = [
        ./blockurl.nix
        ./borg.nix

        ./ddns-updater.nix


        ./mosquitto.nix
        ./nginx-proxy-manager.nix
        ./nginx-vhosts.nix
        ./nginx.nix
        ./pi-hole.nix
        ./qbittorrent.nix
        ./radicale.nix
        ./stremio-export.nix
        ./syncthing.nix
        ./traccar.nix
        ./trakttv-backup.nix
        ./trilium.nix
        ./trilium-sysadmin.nix
        ./home-automation
        ./monitoring
    ];
}
