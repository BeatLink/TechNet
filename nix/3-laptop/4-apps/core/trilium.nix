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
                        # A second pair of roots, beside the first rather than inside it, holding the instance Thor opens over waypipe
                        ".config/trilium-waypipe"
                        ".local/share/trilium-waypipe"
                    ];

                };
                file = {
                    ".config/autostart/trilium-next.desktop".source =
                        "${trilium-desktop}/share/applications/Trilium.desktop";
                };
            };
        };
}
