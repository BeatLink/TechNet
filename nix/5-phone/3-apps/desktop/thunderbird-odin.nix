# Thunderbird on Odin, displayed here over waypipe, on a profile of its own.
#
# A profile is a single-writer store, so this cannot share Odin's; the directory starts empty and is
# seeded by copying one out of Odin's ~/.thunderbird, the same way Firefox's was.
#
# Passed by path rather than -P: a directory absent from profiles.ini gets no toolkit profile entry,
# and Mozilla's remoting is keyed on the profile, so a second one starts rather than handing over.
#
{
    technet.waypipe.apps.thunderbird-odin = {
        title = "Thunderbird (Odin)";
        host = "odin-waypipe";
        icon = ./thunderbird.png; # A copy, so the phone does not carry Thunderbird in its closure for one PNG
        categories = [
            "Network"
            "Email"
            "Office"
        ];

        command = [
            "thunderbird"
            "--profile"
            "/Storage/PhoneApps/Thunderbird/Thor"
        ];

        # Odin's GTK apps otherwise reach for its own session rather than waypipe's display
        environment.GDK_BACKEND = "wayland";
    };
}
