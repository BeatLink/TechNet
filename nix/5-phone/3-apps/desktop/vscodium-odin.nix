# VSCodium on Odin, displayed here over waypipe, as a second instance.
#
# --user-data-dir is what makes it a second one: without it the editor already
# running on Odin adopts the launch and opens the window on its own screen.
# Extensions live outside it, so both instances load the same store-managed set.
#
{
    technet.waypipe.apps.vscodium-odin = {
        title = "VSCodium (Odin)";
        host = "odin-waypipe";
        icon = ./vscodium.png; # A copy, so the phone does not carry Electron in its closure for one PNG
        categories = [
            "Utility"
            "TextEditor"
            "Development"
            "IDE"
        ];

        command = [
            "codium"
            "--user-data-dir"
            "/Storage/PhoneApps/VSCodium/Thor"
            # Overrides the wrapper's --ozone-platform-hint=auto, which resolves to X11 over ssh because XDG_SESSION_TYPE is tty there, and leaves a black window
            "--ozone-platform=wayland"
        ];

        # The codium wrapper reads this to add Wayland decorations and text-input v3, which is what the phone's keyboard needs
        environment.NIXOS_OZONE_WL = "1";
    };
}
