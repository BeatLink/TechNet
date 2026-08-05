# Chromium -- here for compatibility, not for speed.
#
# It renders on the CPU like everything else on this phone. Its GPU process asks
# EGL for a GLES 3.0 context, the Mali-400 through lima offers 2.0, and it gives
# up rather than stepping down:
#
#     eglCreateContext ES 3.0 failed with error EGL_BAD_ATTRIBUTE.
#       ES version fallback is disabled.
#     gl::init::CreateGLContext failed
#     Exiting GPU process due to errors during initialization
#
# That is the same wall GTK4 hits, for the same reason, so Chromium is no better
# off than Butler or Epiphany on this hardware. The one engine measured actually
# reaching this GPU is WebKit under GTK3 with GDK_GL=gles, which asks for GLES
# 2.0 and is granted it -- 0.39 cores against 1.52 on the same page.
#
# An earlier note here claimed Chromium was accelerated and roughly twice as
# efficient as WebKit. That was wrong: the phone had rebooted on a flat battery
# between writing the test page and running the comparison, /tmp was cleared,
# and both arms were rendering a file-not-found page rather than the animation.
#
# What it is genuinely for: sites that refuse WebKit outright. WhatsApp Web is
# the case in hand -- it rejects WebKitGTK whatever user agent it is handed, a
# desktop Chrome string and a Safari 17 string included, and Tangram fails on it
# for exactly that reason. Chromium is what such sites are tested against.
#
{ pkgs, ... }:
{
    # The sandbox helper has to be setuid, which only a system-level install can
    # arrange. Without it Chromium runs unsandboxed and says so in a banner
    # across the top of every window: "You are using an unsupported command-line
    # flag: --no-sandbox."
    security.chromiumSuidSandbox.enable = true;

    # Wayland natively rather than through Xwayland, which this host does not
    # even have -- programs.xwayland.enable is false in 1-system/6-display.nix,
    # so an X11 fallback would fail to start rather than merely be slower. The
    # nixpkgs wrapper reads this and passes the ozone flags itself.
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    home-manager.users.beatlink = {
        home = {
            packages = [ pkgs.chromium ];

            # Profile, extensions, cookies and logins. / is rolled back on this
            # host, so without this every login is done again on every boot.
            #
            # The cache is deliberately included: Chromium's disk cache is what
            # keeps a dashboard's JavaScript from being re-parsed on every cold
            # start, which on this CPU is the slowest part of opening one.
            persistence."/Storage/Apps/Core/Chromium" = {
                directories = [
                    ".config/chromium"
                    ".cache/chromium"
                ];
            };
        };
    };
}
