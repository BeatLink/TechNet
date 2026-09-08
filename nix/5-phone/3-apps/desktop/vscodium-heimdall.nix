# VSCodium on Heimdall, displayed here over waypipe.
#
# --user-data-dir holds the single-instance lock, so keeping it here rather than
# at the default means a second launch starts its own process instead of being
# handed to one whose waypipe session has already ended. Extensions live outside
# it, on the store-managed set Heimdall shares with Odin's editor.
#
{
    technet.waypipe.apps.vscodium-heimdall = {
        title = "VSCodium (Heimdall)";
        host = "heimdall-waypipe";
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
