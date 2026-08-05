# GTK3 and GTK4 side by side, for measurement rather than for use.
#
# Every application on this phone is GTK4/libadwaita and every part of the shell
# is GTK3 -- checked, not assumed: phosh, phoc and stevia link libgtk-3 and
# libhandy-1, while Butler, Tangram, Epiphany, Nautilus, Secrets, Chats, Calls
# and Showtime all link libgtk-4 and libadwaita. The shell is the half that
# feels fine.
#
# That is a clean split along the toolkit, so it is worth knowing whether the
# toolkit is what the difference is made of. GTK4 cannot get a GL context here
# -- lima on the Mali-400 is GLES 2.0, GTK4 asks for GLES 3.0 -- so it falls
# back to the cairo renderer that GTK3 rasterises with natively. Whether "GTK4
# through a fallback" and "GTK3 by design" cost the same on the same screen is
# the open question.
#
# The demos are the instrument. Both ship a Fishbowl benchmark that draws as
# many moving widgets as it can hold a frame rate for and reports the count and
# the FPS on screen, which makes the two toolkits directly comparable on one
# device -- the only such pairing available, since gtk4-rendernode-tool has no
# GTK3 equivalent. They are in each package's `dev` output, and are linked here
# with their own launchers because the app grid is the only way to start
# anything on a phone.
#
# nemo is the applied version of the same question. It is a file manager and
# this host already runs Nautilus, so it is one task with one variable changed;
# every other GTK3 candidate would compare two different applications. Nemo was
# deliberately dropped from this host in favour of Nautilus (see nautilus.nix)
# because it is built for a mouse and a wide window -- that judgement stands and
# this does not reverse it. It is here to be measured, not to be used.
#
# xed is a second GTK3 sample with no GTK4 counterpart installed, so it says
# whether GTK3 is comfortable here rather than settling the comparison. The
# attribute is xed-editor: `xed` is Intel's X86 Encoder Decoder, which is marked
# broken on aarch64 and fails evaluation rather than being skipped.
#
# nemo and xed are Cinnamon components and bring xapp and cinnamon-desktop with
# them. Delete this file when the question is answered; nothing refers to it.
{ pkgs, ... }:
let
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
            gtk-demos
        ];
    };
}
