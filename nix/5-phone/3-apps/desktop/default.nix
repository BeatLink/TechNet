# Desktop applications
#
# Every application here runs on Odin and is displayed on this phone over waypipe; nothing in this folder executes on the phone's own CPU or GPU.
#
{
    imports = [
        ./firefox-odin.nix
        ./freetube.nix
        ./home-assistant.nix
        ./keepassxc-odin.nix
        ./pix-odin.nix
        ./trilium.nix
        ./vlc-odin.nix
        ./vscodium-odin.nix
        ./xviewer-odin.nix
    ];
}
