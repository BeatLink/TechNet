# Screenshots
#
# gnome-screenshot (configured in 4-apps/tools/screenshot.nix) cannot capture under Wayland, so grim/slurp are
# used instead. grimblast wraps them to provide region, window and full screen capture.
#
# Each mode also gets a desktop entry. Context is the application launcher now, and it lists desktop entries, so
# without these a screenshot is only reachable from a key — not searchable, and not something a context can hold.
#

{ pkgs, ... }:
let
    modes = [
        {
            id = "screenshot-area";
            name = "Screenshot Area";
            comment = "Select a region to capture";
            target = "area";
            icon = "screenshot";
        }
        {
            id = "screenshot-screen";
            name = "Screenshot Screen";
            comment = "Capture the whole screen";
            target = "screen";
            icon = "camera-photo";
        }
        {
            id = "screenshot-window";
            name = "Screenshot Window";
            comment = "Capture the focused window";
            target = "active";
            icon = "window";
        }
    ];
in
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
                grim
                slurp
                grimblast
                swappy # Annotate captures
            ];

            wayland.windowManager.hyprland.settings.bind = [
                ", Print, exec, ${pkgs.grimblast}/bin/grimblast --notify copysave screen"
                "SHIFT, Print, exec, ${pkgs.grimblast}/bin/grimblast --notify copysave area"
                "$mod, Print, exec, ${pkgs.grimblast}/bin/grimblast --notify copysave active"
            ];

            xdg.desktopEntries = builtins.listToAttrs (
                map (mode: {
                    name = mode.id;
                    value = {
                        name = mode.name;
                        comment = mode.comment;
                        # copysave puts the capture on the clipboard and in the pictures directory, so it is
                        # usable immediately either way.
                        exec = "${pkgs.grimblast}/bin/grimblast --notify copysave ${mode.target}";
                        icon = mode.icon;
                        terminal = false;
                        categories = [
                            "Utility"
                            "Graphics"
                        ];
                    };
                }) modes
            );
        };
}
