# Waydroid
#
# Thor's Android container, displayed here. The container is the phone's and there is only one, so launching this takes Waydroid off the phone's screen
# until the session ends; Thor resizes its panel to this screen for as long as it is held, and puts its own back afterwards.
#
{
    config = {
        technet.waypipe.apps = {
            waydroid-thor = {
                title = "Waydroid (Thor)";
                host = "thor-waypipe";
                icon = ./waydroid.png; # A copy, so this host does not carry Waydroid in its closure for one PNG
                categories = [
                    "System"
                    "Emulator"
                ];

                audio = true; # waypipe carries Wayland alone, so without this every Android app plays out of the phone
                audioLatency = 400; # Sized for mobile data, where the round trip has swung between 65ms and 334ms

                # Holds the session for as long as it runs: closing an Android window does not end it, and quitting the launcher hands Waydroid back to the phone
                command = [ "waydroid-remote" ];
            };

            waydroid-thor-release = {
                title = "Waydroid (Thor) — Release";
                host = "thor-waypipe";
                icon = ./waydroid.png;
                categories = [
                    "System"
                    "Emulator"
                ];

                command = [
                    "waydroid-remote"
                    "release"
                ];
            };
        };
    };
}
