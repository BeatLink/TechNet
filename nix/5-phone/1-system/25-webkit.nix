# WebKitGTK, on a GPU it cannot use.
#
# Every GTK4 WebKit application on this phone -- Epiphany and, at the time,
# Tangram and Butler --
# segfaulted within a minute of opening a page. Same crash each time, in the UI
# process rather than the web process:
#
#     #0  WebKit::AcceleratedBackingStore::update (LayerTreeContext const&)
#     #1  WebKit::WebPageProxy::enterAcceleratedCompositingMode (...)
#     #2  WebKit::DrawingAreaProxyCoordinatedGraphics::enterAcceleratedCompositingMode
#
# The cause is upstream of WebKit. GTK4 cannot get a GL context here at all --
# with GDK_DEBUG=opengl it tries GLES 3.0, then GL 3.3, then GL 3.3 legacy, and
# every one fails, because the Mali-400 through lima is GLES 2.0 and nothing
# more. GTK then says so and falls back:
#
#     Disabled hardware acceleration because GTK failed to initialize GL:
#       Unable to create a GL context
#     Using renderer 'GskCairoRenderer' for surface 'GdkWaylandToplevel'
#
# WebKit's UI-side AcceleratedBackingStore is the thing that would import the
# web process's buffer as a GL texture, so with no context it is never created.
# The web process does not know that and enters accelerated compositing mode
# anyway; the message arrives, the UI process dereferences a backing store that
# is not there, and the window dies. Which is why this reads as "Oops! Something
# went wrong while displaying the page" rather than as anything about graphics.
#
# So the compositing mode is turned off on the side that can still choose. The
# content then rasterises through Skia's CPU path and reaches the UI process as
# shared memory instead of a DMA-BUF texture -- which is what was happening in
# every non-crashing frame regardless, since no part of this stack had a GPU
# context to render into.
#
# Nothing is given up that this device had. Accelerated compositing is what
# gives layers their own textures for the GPU to transform; with no GPU
# available to any client here, its only remaining effect was the crash. WebGL
# and 3D transforms depend on it and will not work -- they did not work before
# either, they failed less clearly.
#
# The thing that would undo this is a GL 3.3 / GLES 3.0 driver, not a setting.
#
# environment.sessionVariables for the same reason GSK_RENDERER uses it in
# 18-performance.nix: phosh.service runs with PAMName = "login", so pam_env
# applies this to the session and everything launched from the app grid inherits
# it. A shell-profile variable would reach an ssh login and nothing the user
# taps.
#
# ----------------------------------------------------------------------------------------------------------------------------------------------------
# This applies to GTK4 only, and deliberately stays the default.
#
# GTK3 is not subject to any of the above. It asks for desktop GL 3.2 by
# default and is refused like GTK4 -- but GDK_GL=gles makes it request GLES
# instead, and lima grants it: "Creating EGL context version 2.0 (es:yes)", with
# no "Disabled hardware acceleration" line after it. WebKit under GTK3
# (webkit2gtk-4.1, the same 2.52.5 engine) then composites through it, measured
# on the same animating page:
#
#     GDK_GL=gles     UI 0.22 + web 0.16 = 0.39 cores   GPU  34%   accel on
#     default         UI 0.70 + web 0.82 = 1.52 cores   GPU 100%   accel off
#
# 3.9x less CPU, and less GPU with it -- because the software path changes the
# whole surface every frame, so phoc re-uploads and recomposites 720x1440
# continuously, while the accelerated path renders layers once and moves them.
#
# So this variable must NOT reach a GTK3 WebKit application: there it turns a
# working GPU path back into the software one. It stays session-wide because
# every WebKit application on this host is GTK4 and would crash without it, and
# a GTK4 one added later should be safe by default rather than by memory. GTK3
# WebKit applications opt out individually, by being wrapped with the variable
# unset and GDK_GL set -- see 3-apps/system/toolkit-comparison.nix for the
# worked example.
{ ... }:
{
    environment.sessionVariables.WEBKIT_DISABLE_COMPOSITING_MODE = "1";
}
