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
    home-manager.users.beatlink = {
        home = {
            packages = [ trilium-desktop ];
            persistence."/Storage/Apps/Core/Trilium" = {
                directories = [
                    ".local/share/trilium-data"
                    ".config/trilium-37840" # Electron userData; Trilium names it after its port, so TRILIUM_PORT changes this path
                ];
            };
        };

        # A unit rather than an autostart .desktop, so this Electron app runs in a cgroup of its own.
        # Electron takes both the wm_class and the userData name from the asar's package.json, so a build handing it a loose main.cjs instead breaks the panel match and the persisted path at once
        systemd.user.services.trilium = {
            Unit = {
                Description = "Trilium Notes";
                PartOf = [ "graphical-session.target" ];
                Requires = [ "display.target" ];
                After = [ "display.target" ];
            };
            Service = {
                ExecStart = "${trilium-desktop}/bin/trilium";
                Restart = "on-failure";
                RestartSec = 5;
            };
            Install.WantedBy = [ "display.target" ];
        };
    };
}
