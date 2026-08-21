{ inputs, pkgs, ... }:
let
    # nixpkgs is still on 0.104.1, so this is built from upstream's own flake; its wrapper reads NIXOS_OZONE_WL, unlike the nixpkgs one, so no Wayland flags need spelling out here
    trilium-desktop = inputs.trilium.packages.${pkgs.stdenv.hostPlatform.system}.desktop;
in
{
    home-manager.users.beatlink = {
        home = {
            packages = [ trilium-desktop ];
            persistence."/Storage/Apps/Core/Trilium" = {
                directories = [
                    ".local/share/trilium-data"
                    ".config/trilium-37840" # Electron userData; Trilium names it after its port, so TRILIUM_PORT changes this path
                ];
            };
            file = {
                ".config/autostart/trilium-next.desktop".source =
                    "${trilium-desktop}/share/applications/Trilium Notes.desktop";
            };
        };
    };
}
