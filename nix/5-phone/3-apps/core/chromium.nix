# Chromium -- the only engine on this phone that renders on the GPU.
#
# The Mali-400 through lima is GLES 2.0, and GTK4 asks for GLES 3.0, so every
# GTK4 application here -- Butler, Tangram, Epiphany, and the WebKit inside them
# -- falls back to rasterising on four 1.15GHz A53 cores. Chromium does not ask
# a toolkit for its GL context, it creates its own, and it turns out not to
# blocklist lima. Measured on the same animating page, same device:
#
#     Chromium, GPU               0.19 cores   GPU 14%   182MB
#     Chromium, --disable-gpu     0.66 cores   GPU 28%   296MB
#     WebKit GTK3 + GDK_GL=gles   0.39 cores   GPU 34%
#     WebKit GTK3, software       1.52 cores   GPU 100%
#
# So it is roughly twice as efficient as the best WebKit can manage here, and
# 3.5x its own software path.
#
# The other reason it is here is compatibility. WhatsApp Web refuses WebKitGTK
# whatever user agent it is given -- a desktop Chrome string and a Safari 17
# string were both rejected, and Tangram fails the same way for the same reason.
# Chromium is what those sites are tested against.
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
