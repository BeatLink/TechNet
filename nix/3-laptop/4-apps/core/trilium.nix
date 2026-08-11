{ ... }:
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        let
            trilium-desktop = pkgs.trilium-desktop;
        in
        {
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
                        "${trilium-desktop}/share/applications/Trilium.desktop";
                };
            };
        };
}
