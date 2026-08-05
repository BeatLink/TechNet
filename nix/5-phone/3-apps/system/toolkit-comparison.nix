# Toolkit probes -- installed to answer questions, not to be used.
#
# The phone splits cleanly along the toolkit. Every part of the shell is GTK3
# (phosh, phoc and stevia link libgtk-3 and libhandy-1) and every application is
# GTK4/libadwaita (Butler, Tangram, Epiphany, Nautilus, Secrets, Chats, Calls,
# Showtime). The shell is the half that feels fine, and that is the same line
# the complaint falls along.
#
# Underneath it: lima on the Mali-400 is GLES 2.0, GTK4 asks for GLES 3.0 and is
# refused, so it falls back to the cairo renderer GTK3 rasterises with natively.
# Three separate questions come out of that, and this file carries one
# instrument for each.
#
#   1. Does GTK4-through-a-fallback cost more than GTK3-by-design?
#
#      gtk3-demo and gtk4-demo both ship the Fishbowl benchmark, which adds
#      moving widgets until it can no longer hold the frame rate and reports the
#      count and FPS on screen. One device, one benchmark, toolkit as the only
#      variable -- the only such pairing available, since gtk4-rendernode-tool
#      has no GTK3 equivalent. They live in each package's `dev` output and are
#      linked here with their own launchers, because the app grid is the only
#      way to start anything on a phone.
#
#      nemo is the applied version: a file manager against Nautilus, one task
#      with one variable changed. Nemo was deliberately dropped from this host
#      in favour of Nautilus (see nautilus.nix) because it is built for a mouse
#      and a wide window. That judgement stands; this does not reverse it.
#
#      xed is a second GTK3 sample with no GTK4 counterpart, so it says whether
#      GTK3 is comfortable here rather than settling the comparison. The
#      attribute is xed-editor: `xed` is Intel's X86 Encoder Decoder, marked
#      broken on aarch64, and it fails evaluation rather than being skipped.
#
#   2. Can WebKit get a GL context under GTK3, having been refused under GTK4?
#
#      This is the interesting one. WebKitGTK ships parallel API series from one
#      source tree: webkitgtk-6.0 is GTK4, webkit2gtk-4.1 is GTK3, and nixpkgs
#      has both at 2.52.5 -- the same engine, a different toolkit. The crash
#      documented in 1-system/25-webkit.nix was never WebKit's doing: GTK4 could
#      not create a GL context, so the UI-side AcceleratedBackingStore was never
#      built, and the web process entered compositing mode regardless. GTK3's
#      context creation supports GLES 2.0, which is exactly what this GPU has.
#
#      Answered, and the answer is yes -- but only when GTK3 is told to ask for
#      GLES. Left alone it requests desktop GL 3.2 and is refused exactly like
#      GTK4; with GDK_GL=gles it gets "EGL context version 2.0 (es:yes)" and no
#      "Disabled hardware acceleration" line, and WebKit composites through it.
#      Measured on the same animating page:
#
#          GDK_GL=gles   UI 0.22 + web 0.16 = 0.39 cores   GPU  34%   accel on
#          default       UI 0.70 + web 0.82 = 1.52 cores   GPU 100%   accel off
#
#      So luakit is wrapped rather than installed bare: GDK_GL set, and the
#      session-wide WEBKIT_DISABLE_COMPOSITING_MODE from 1-system/25-webkit.nix
#      unset, since that variable exists for the GTK4 crash and would put this
#      back on the software path. The wrapper is why it is `luakit` on PATH and
#      in the app grid without the unwrapped package being installed at all.
#
#      What this does and does not buy: rasterising the page stays on the CPU in
#      Skia either way. Compositing is what moves to the GPU, so the gain is in
#      scrolling and animation rather than in first paint or JavaScript.
#
#   3. Does Qt Quick reach the GPU where GTK4 cannot?
#
#      Qt's scene graph was built against GLES 2.0 and still targets it, which
#      makes it the one mainstream toolkit whose floor matches this hardware --
#      it is why Plasma Mobile is accelerated on devices of this class. qml from
#      qtdeclarative runs a QML file directly, and QSG_INFO=1 makes it print the
#      backend and GL version it obtained, which is the exact analogue of
#      GDK_DEBUG=opengl on the GTK side.
#
# Delete this file once the three are answered; nothing else refers to it.
{ pkgs, ... }:
let
    # GTK3 asks for desktop GL unless told otherwise, and the session-wide
    # compositing switch is aimed at GTK4. Both have to be corrected here or the
    # GPU path is not taken.
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

    gtk-demos = pkgs.runCommand "gtk-demos" { } ''
        mkdir -p $out/bin $out/share/applications

        ln -s ${pkgs.gtk3.dev}/bin/gtk3-demo $out/bin/gtk3-demo
        ln -s ${pkgs.gtk4.dev}/bin/gtk4-demo $out/bin/gtk4-demo

        cat > $out/share/applications/gtk3-demo-benchmark.desktop <<EOF
        [Desktop Entry]
        Type=Application
        Name=GTK3 Demo
        Comment=GTK3 widget gallery and Fishbowl benchmark
        Exec=${pkgs.gtk3.dev}/bin/gtk3-demo
        Icon=applications-development
        Terminal=false
        Categories=Development;
        EOF

        cat > $out/share/applications/gtk4-demo-benchmark.desktop <<EOF
        [Desktop Entry]
        Type=Application
        Name=GTK4 Demo
        Comment=GTK4 widget gallery and Fishbowl benchmark
        Exec=${pkgs.gtk4.dev}/bin/gtk4-demo
        Icon=applications-development
        Terminal=false
        Categories=Development;
        EOF
    '';
in
{
    home-manager.users.beatlink = {
        home.packages = [
            pkgs.nemo
            pkgs.xed-editor
            luakit-gles
            pkgs.qt6.qtdeclarative
            gtk-demos
        ];
    };
}
