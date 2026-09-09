# Chromium, wrapped for a GPU it cannot use.
#
# Measured on this phone, 25s each with --ozone-platform=wayland, counting "Exiting GPU process":
#
#     wayland only        3 deaths, 6x "eglCreateContext ES 3.0 failed"
#     --use-angle=opengles 5 deaths
#     --use-angle=opengl   3 deaths
#     --use-angle=swiftshader / --disable-gpu   0 deaths
#
# So the GPU process is not merely unaccelerated here, it crashes and restarts while trying. Chromium 152
# allows only ANGLE-backed GL -- `--use-gl=egl` is refused as "not found in allowed implementations", which
# is why the flag that works for Electron 43 does nothing here. --disable-gpu is the one stable answer.
#
# Bare, with no ozone flag, it exits immediately: it looks for a display it cannot find under phosh.
#
{ pkgs, ... }:
let
    chromium-wayland = pkgs.symlinkJoin {
        name = "chromium-wayland";
        paths = [ pkgs.chromium ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
            wrapProgram $out/bin/chromium \
                --add-flags "--ozone-platform=wayland" \
                --add-flags "--disable-gpu" \
                --add-flags "--enable-wayland-ime=true" \
                --add-flags "--wayland-text-input-version=3"
        '';
    };
in
{
    home-manager.users.beatlink = {
        home = {
            packages = [ chromium-wayland ];

            persistence."/Storage/Apps/Core/Chromium" = {
                directories = [ ".config/chromium" ];
            };
        };
    };
}
