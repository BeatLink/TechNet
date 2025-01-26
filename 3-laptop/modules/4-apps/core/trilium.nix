{
    nixpkgs.config.permittedInsecurePackages = [
        "electron-31.7.7"
    ];
    home-manager.users.beatlink = { config, pkgs, ... }: {
        nixpkgs.config.permittedInsecurePackages = [
            "electron-31.7.7"
        ];
        home = {
            packages = with pkgs; [ trilium-next-desktop ];
            persistence."/Storage/Apps/Core/Trilium" = {
                directories = [
                    ".local/share/trilium-data"
                    ".config/TriliumNext Notes"
                ];
                allowOther = true;
            };
        };
    };
}