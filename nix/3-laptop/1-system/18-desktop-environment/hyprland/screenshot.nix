# Screenshots
#
# gnome-screenshot (configured in 4-apps/tools/screenshot.nix) cannot capture under Wayland, so grim/slurp are
# used instead. grimblast wraps them to provide region, window and full screen capture.
#
# This laptop has no Print key, so the Super+Shift bindings are the ones that actually work; the Print bindings
# are kept for an external keyboard. S is for snip, P for print and A for the active window.
#
# grimblast writes to XDG_PICTURES_DIR, which ../../../0-common/1-system/5-folder-structure.nix points at /Storage/Files/Pictures.
#
# Each mode also gets a desktop entry. Context is the application launcher now, and it lists desktop entries, so
# without these a screenshot is only reachable from a key - not searchable, and not something a context can hold.
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
            key = "S";
            printKey = "SHIFT, Print";
        }
        {
            id = "screenshot-screen";
            name = "Screenshot Screen";
            comment = "Capture the whole screen";
            target = "screen";
            icon = "camera-photo";
            key = "P";
            printKey = ", Print";
        }
        {
            id = "screenshot-window";
            name = "Screenshot Window";
            comment = "Capture the focused window";
            target = "active";
            icon = "window";
            key = "A";
            printKey = "$mod, Print";
        }
    ];

    capture = target: "${pkgs.grimblast}/bin/grimblast --notify copysave ${target}";

    # Capturing something that holds the keyboard needs a delay, because the keybind that would take the shot
    # never reaches the compositor while it is up. Context's editor and switcher are layer surfaces with an
    # exclusive keyboard grab, and so are most menus. Fire this, open the thing, and wait.
    #
    # Layer surfaces are included in a full screen capture - grim takes the composited output, so the bars, the
    # wallpaper and Context's own sidebar all appear. That is why this is screen only: there is no window to
    # point at, since a layer surface is not a window.
    delayedCapture = pkgs.writeShellApplication {
        name = "screenshot-delayed";
        runtimeInputs = [
            pkgs.grimblast
            pkgs.libnotify
            pkgs.coreutils
        ];
        text = ''
            delay="''${1:-5}"
            notify-send -t $((delay * 1000)) "Screenshot in ''${delay}s" "Open what you want to capture."
            sleep "$delay"
            grimblast --notify copysave screen
        '';
    };
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

            wayland.windowManager.hyprland.settings.bind =
                builtins.concatMap (mode: [
                    "$mod SHIFT, ${mode.key}, exec, ${capture mode.target}"
                    "${mode.printKey}, exec, ${capture mode.target}"
                ]) modes
                ++ [ "$mod SHIFT, D, exec, ${delayedCapture}/bin/screenshot-delayed 5" ];

            xdg.desktopEntries = {
                screenshot-delayed = {
                    name = "Screenshot after a Delay";
                    comment = "Capture the whole screen in five seconds, menus and panels included";
                    exec = "${delayedCapture}/bin/screenshot-delayed 5";
                    icon = "camera-photo";
                    terminal = false;
                    categories = [
                        "Utility"
                        "Graphics"
                    ];
                };
            } // builtins.listToAttrs (
                map (mode: {
                    name = mode.id;
                    value = {
                        name = mode.name;
                        comment = mode.comment;
                        # copysave puts the capture on the clipboard and in the pictures directory, so it is
                        # usable immediately either way.
                        exec = capture mode.target;
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
