# luakit -- GTK3 WebKit, the one browser engine on this phone that reaches the GPU.
#
# Same 2.52 engine as Epiphany, but under GTK3, which takes a GLES context where GTK4 is refused one.
# webkit.nix measured it on an animating page: 0.39 cores and 34% GPU with compositing on, against 1.52
# cores and 100% GPU without.
#
# Wrapped rather than installed bare, because both corrections are needed: GTK3 asks for desktop GL unless
# told otherwise, and the session-wide WEBKIT_DISABLE_COMPOSITING_MODE exists for the GTK4 crash and would
# put this straight back on the software path.
#
# What it buys is scrolling and animation. Rasterising stays on the CPU in Skia either way, so first paint
# and JavaScript are unchanged -- and the interface is keyboard-driven, which a touchscreen does not suit.
#
{ pkgs, ... }:
let
    luakit-gles = pkgs.symlinkJoin {
        name = "luakit-gles";
        paths = [ pkgs.luakit ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
            wrapProgram $out/bin/luakit \
                --set GDK_GL gles \
                --unset WEBKIT_DISABLE_COMPOSITING_MODE
        '';
    };
in
{
    home-manager.users.beatlink = {
        home = {
            packages = [ luakit-gles ];

            persistence."/Storage/Apps/Core/Luakit" = {
                directories = [
                    ".local/share/luakit"
                    ".config/luakit"
                ];
            };
        };
    };
}
