# Valent on Heimdall, displayed here over waypipe.
#
# What this shows is Heimdall's pairings rather than the phone's: nothing on Thor answers the KDE Connect protocol any more, so the other hosts see
# one peer fewer and this window is a view of that host's devices instead of a device of its own.
#
{
    technet.valent.enable = false; # Two copies on one screen would be two peers on the network, and this is the one with a keyboard behind it

    technet.waypipe.apps.valent-heimdall = {
        title = "Valent (Heimdall)";
        host = "heimdall-waypipe";
        icon = ./valent.png; # A copy, so the phone does not carry valent in its closure for one PNG
        categories = [
            "Network"
            "Utility"
        ];

        command = [ "valent" ];

        # Pinned so the toolkit takes waypipe's display rather than probing for another
        environment.GDK_BACKEND = "wayland";
    };
}
