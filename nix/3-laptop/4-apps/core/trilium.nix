{ ... }:
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        let
            trilium-desktop = pkgs.symlinkJoin {
                name = "trilium-desktop";
                paths = [ pkgs.trilium-desktop ];
                nativeBuildInputs = [ pkgs.makeWrapper ];
                # Its wrapper reads no NIXOS_OZONE_WL, so the flags that switch it off X11 are spelled out here, as they are for Thor's instance in 5-phone
                postBuild = ''
                    wrapProgram $out/bin/trilium --add-flags "--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true"
                '';
            };
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
