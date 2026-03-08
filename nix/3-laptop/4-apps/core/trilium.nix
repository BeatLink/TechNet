{
    home-manager.users.beatlink =
        { inputs, pkgs, ... }:
        let
            trilium = inputs.trilium-notes.packages.${pkgs.stdenv.hostPlatform.system}.desktop;
        in
        {
            home = {
                packages = [ trilium ];
                persistence."/Storage/Apps/Core/Trilium" = {
                    directories = [
                        ".local/share/trilium-data"
                        ".config/Trilium Notes"
                    ];

                };
                file = {
                    ".config/autostart/trilium-next.desktop".source =
                        "${trilium}/share/applications/Trilium.desktop";
                };
            };
        };
}
