{ lib, ... }:

with lib.hm.gvariant;

{
    dconf.settings = {
        "org/cinnamon/sounds" = {
            login-enabled = true;
            login-file = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/desktop-login.ogg";

            logout-enabled = true;
            logout-file = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/desktop-logout.ogg";

            switch-enabled = true;
            switch-file = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/message-new-instant.ogg";

            map-enabled = true;
            map-file = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/service-login.ogg";

            close-enabled = true;
            close-file = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/service-logout.ogg";

            minimize-enabled = true;
            minimize-file = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/button-pressed.ogg";

            maximize-enabled = true;
            maximize-file = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/button-toggle-on.ogg";

            unmaximize-enabled = true;
            unmaximize-file = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/button-toggle-off.ogg";

            tile-enabled = true;
            tile-file = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/button-toggle-on.ogg";

            plug-enabled = true;
            plug-file = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/service-login.ogg";

            unplug-enabled = true;
            unplug-file = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/service-logout.ogg";

            notification-enabled = true;
            notification-file = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/service-login.ogg";
            
        };

        "org/cinnamon/desktop/sound" = {
            allow-amplified-volume = true;
            maximum-volume = 150;
            volume-sound-enabled = true;
            volume-sound-file = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/message-new-instant.ogg";
        };

    };
}