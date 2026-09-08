# Desktop applications
#
# Every application here runs on Heimdall and is displayed on this phone over waypipe; nothing in this folder executes on the phone's own CPU or GPU.
#
{
    imports = [
        ./discord-heimdall.nix
        ./element-heimdall.nix
        ./firefox-heimdall.nix
        ./freetube.nix
        ./gmusicbrowser-heimdall.nix
        ./home-assistant.nix
        ./keepassxc-heimdall.nix
        ./libreoffice-heimdall.nix
        ./newsflash-heimdall.nix
        ./pix-heimdall.nix
        ./quodlibet-heimdall.nix
        ./thunderbird-heimdall.nix
        ./trilium.nix
        ./vlc-heimdall.nix
        ./vscodium-heimdall.nix
        ./xreader-heimdall.nix
        ./xviewer-heimdall.nix
    ];
}
