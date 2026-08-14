# Wayland Clients ####################################################################################################################################
#
# GTK, Qt 6 and Gecko all pick Wayland on their own under a Wayland session. Qt 5 and Chromium do not, so this sets the switch each of them reads.
# Both switches fall back to X11 when there is no compositor, so an X11 session is unaffected. The Chromium apps whose wrapper ignores NIXOS_OZONE_WL
# spell the flags out themselves, in their own module under ../../4-apps.
#

{
    environment.sessionVariables = {
        NIXOS_OZONE_WL = "1"; # Read by the nixpkgs Chromium and Electron wrappers, which add their Wayland flags only when WAYLAND_DISPLAY is set too
        QT_QPA_PLATFORM = "wayland;xcb"; # Qt takes the entries in turn, so Qt 5 stops defaulting to xcb while keeping it as the fallback
    };
}
