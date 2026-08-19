# Discord on Odin, displayed here over waypipe.
#
# --user-data-dir is what makes it a second process; the account is logged in per data directory, so
# this instance signs in on its own and shows up as a second session.
#
{
    technet.waypipe.apps.discord-odin = {
        title = "Discord (Odin)";
        host = "odin-waypipe";
        icon = ./discord.png; # A copy, so the phone does not carry Electron in its closure for one PNG
        categories = [
            "Network"
            "InstantMessaging"
            "Chat"
        ];

        audio = true; # waypipe carries Wayland alone, so without this voice and notifications come out of Odin
        audioLatency = 400; # Sized for mobile data, where the round trip has swung between 65ms and 334ms

        command = [
            "discord"
            # The `=` form, because the FHS launcher hands argv straight to Electron rather than to a shell that would split a separate word
            "--user-data-dir=/Storage/PhoneApps/Discord/Thor"
            # Discord's FHS launcher ignores NIXOS_OZONE_WL, so the flags it would have added are spelled out here; the last two are what the phone's keyboard types through
            "--ozone-platform=wayland"
            "--enable-features=WaylandWindowDecorations"
            "--enable-wayland-ime=true"
            "--wayland-text-input-version=3"
        ];
    };
}
