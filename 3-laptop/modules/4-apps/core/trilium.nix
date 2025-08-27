{
    nixpkgs.config.permittedInsecurePackages = [
        "electron-31.7.7"
    ];
    home-manager.users.beatlink = { pkgs, ... }: {
        nixpkgs.config.permittedInsecurePackages = [
            "electron-31.7.7"
        ];
        home = {
            packages = with pkgs; [ trilium-desktop ];
            persistence."/Storage/Apps/Core/Trilium" = {
                directories = [
                    ".local/share/trilium-data"
                    ".config/Trilium Notes"
                ];
                allowOther = true;
            };
            file = {
                ".config/autostart/trilium-next.desktop".source = "${pkgs.trilium-desktop}/share/applications/Trilium.desktop";
            };
        };
    };
}