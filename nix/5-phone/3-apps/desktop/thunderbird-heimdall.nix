# Thunderbird on Heimdall, displayed here over waypipe, on a profile of its own.
#
# A profile is a single-writer store, so this keeps one to itself; the directory starts empty and is
# seeded by copying one in, the same way Firefox's was.
#
# Passed by path rather than -P: a directory absent from profiles.ini gets no toolkit profile entry,
# and Mozilla's remoting is keyed on the profile, so a second one starts rather than handing over.
#
{
    technet.waypipe.apps.thunderbird-heimdall = {
        title = "Thunderbird (Heimdall)";
        host = "heimdall-waypipe";
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

        # Pinned so the toolkit takes waypipe's display rather than probing for another
        environment.GDK_BACKEND = "wayland";
    };
}
