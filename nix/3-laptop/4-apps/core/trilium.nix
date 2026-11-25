{ pkgs, ... }:
let
    # Its wrapper reads no NIXOS_OZONE_WL, so the flags that switch it off X11 are spelled out here, as they are for Thor's instance in 5-phone
    trilium-desktop = pkgs.symlinkJoin {
        name = "trilium-desktop";
        paths = [ pkgs.trilium-desktop ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
            wrapProgram $out/bin/trilium --add-flags "--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true"
        '';
    };
in
{
    technet.desktop.apps = {
        # Electron takes both the wm_class and the userData name from the asar's package.json, so a build handing it a loose main.cjs instead breaks the panel match and the persisted path at once
        trilium = {
            description = "Trilium Notes";
            command = "${trilium-desktop}/bin/trilium";
            desktopFile = "${trilium-desktop}/share/applications/Trilium.desktop";
            socket = "$HOME/.config/trilium-37840/SingletonSocket";
        };
        trilium-sysadmin = {
            description = "Trilium Sysadmin Notes";
            command = "${trilium-desktop}/bin/trilium";
        };
    };

    home-manager.users.beatlink = {
        home = {
            packages = [ trilium-desktop ];
            persistence."/Storage/Apps/Core/Trilium" = {
                directories = [
                    ".local/share/trilium-data"
                    ".local/share/trilium-data-sysadmin"
                    ".config/trilium-37840" # Electron userData; Trilium names it after its port, so TRILIUM_PORT changes this path
                    ".config/trilium-12351"
                ];
            };
        };

        systemd.user.services.trilium-sysadmin.Service.Environment = [
            "TRILIUM_PORT=12351"
            "TRILIUM_DATA_DIR=/home/beatlink/.local/share/trilium-data-sysadmin"
            "TRILIUM_ELECTRON_DATA_DIR=/home/beatlink/.config/trilium-12351"
        ];
    };
}
