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
                        ".config/Trilium Notes"
                    ];

                };
                file = {
                    ".config/autostart/trilium-next.desktop".source =
                        "${trilium-desktop}/share/applications/Trilium.desktop";
                };
            };
        };
}
