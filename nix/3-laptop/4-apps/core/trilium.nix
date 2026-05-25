{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = [ pkgs.trilium-desktop ];
                persistence."/Storage/Apps/Core/Trilium" = {
                    directories = [
                        ".local/share/trilium-data"
                        ".config/Trilium Notes"
                    ];

                };
                file = {
                    ".config/autostart/trilium-next.desktop".source =
                        "${pkgs.trilium-desktop}/share/applications/Trilium Notes.desktop";
                };
            };
        };
}
