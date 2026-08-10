# Toolkit probes -- installed to answer questions, not to be used.
#
# The phone splits cleanly along the toolkit. Every part of the shell is GTK3
# (phosh, phoc and stevia link libgtk-3 and libhandy-1) and every application is
# GTK4/libadwaita (Nautilus, Secrets, Chats, Calls, Showtime). The
# shell is the half that feels fine, and that is the same line
# the complaint falls along.
#
# Underneath it: lima on the Mali-400 is GLES 2.0, GTK4 asks for GLES 3.0 and is
# refused, so it falls back to the cairo renderer GTK3 rasterises with natively.
# Three separate questions come out of that, and this file carries one
# instrument for each.
#
#   1. Does GTK4-through-a-fallback cost more than GTK3-by-design?
#
#      Answered, and acted on: chargectl is Vala on GTK3/libhandy because of it.
#      The Fishbowl pairing that settled it -- gtk3-demo against gtk4-demo, one
#      device, toolkit as the only variable -- has been removed.
#
#      The two applied samples stayed and are now installed for their own sake
#      rather than as instruments: nemo.nix (a file manager against Nautilus)
#      and xed.nix (a GTK3 editor with no GTK4 counterpart here).
#
#   2. Can WebKit get a GL context under GTK3, having been refused under GTK4?
#
#      Answered: yes, but only when GTK3 is told to ask for GLES. Left alone it
#      requests desktop GL 3.2 and is refused exactly like GTK4; with
#      GDK_GL=gles it gets "EGL context version 2.0 (es:yes)" and WebKit
#      composites through it -- 0.39 cores against 1.52 on an animating page.
#
#      luakit was the probe and has been removed. So has WebLaunch, which was
#      what the answer bought: every web app is a waypipe app now, rendered on
#      Odin, so no browser engine runs on this GPU at all.
#
#      Worth recording what the answer did not buy, since it is easy to
#      overread: a Home Assistant dashboard still scrolls at about 5fps with
#      compositing confirmed active and both processes near idle. The GPU is
#      saturated on fill rate at 720x1440, and no engine choice changes how many
#      pixels a Mali-400 can blend.
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
{
    home-manager.users.beatlink = {
        home.packages = [ pkgs.qt6.qtdeclarative ];
    };
}
