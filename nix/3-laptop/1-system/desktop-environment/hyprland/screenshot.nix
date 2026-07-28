# Screenshots
#
# gnome-screenshot (configured in 4-apps/tools/screenshot.nix) cannot capture under Wayland, so grim/slurp are
# used instead. grimblast wraps them to provide region, window and full screen capture.
#

{ pkgs, ... }:
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
        };
}
