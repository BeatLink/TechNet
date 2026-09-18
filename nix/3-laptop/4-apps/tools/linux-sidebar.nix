{ inputs, pkgs, ... }:
let
    # WebKit divides by the DRM refresh rate, which is 0 while an output is connected but unlit, so pin it to the timer vblank monitor
    linux-sidebar =
        inputs.linux-sidebar.packages.${pkgs.stdenv.hostPlatform.system}.linux-sidebar.overrideAttrs
            (old: {
                preFixup = (old.preFixup or "") + ''
                    gappsWrapperArgs+=(--set WEBKIT_FORCE_VBLANK_TIMER 1)
                '';
            });
in
{
    home-manager.users.beatlink = {
        programs.linux-sidebar = {
            enable = true;
            package = linux-sidebar;
            autostart = false; # The unit below starts it instead, once the display answers
        };

        systemd.user.services.linux-sidebar = {
            Unit = {
                Description = "Linux Sidebar";
                PartOf = [ "graphical-session.target" ];
                Requires = [ "display.target" ];
                After = [ "display.target" ];
            };
            Service = {
                ExecStart = "${linux-sidebar}/bin/linux-sidebar";
                Restart = "on-failure";
                RestartSec = 5;
            };
            Install.WantedBy = [ "display.target" ];
        };
        home = {
            # The settings, the layout and the notes all live here and are written by the
            # app, so none of them can be managed declaratively without making them
            # read-only. Persisting the directory is what keeps the notes.
            persistence."/Storage/Apps/Tools/LinuxSidebar" = {
                directories = [
                    ".config/linux-sidebar"
                ];

            };

            # The first launch copies the old scratchpad's settings and note across, which
            # needs the old store still mounted; this can go once it has run once.
            persistence."/Storage/Apps/Tools/SidebarScratchpad" = {
                directories = [
                    ".config/sidebar-scratchpad"
                ];

            };
        };
    };
}
