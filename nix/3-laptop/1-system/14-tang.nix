{ config, ... }:
{
    technet.tang.server = {
        enable = true;
        sopsFile = "${config.technet.secrets.path}/tang.yaml";
        screensaver = {
            dbusName = "org.cinnamon.ScreenSaver";
            objectPath = "/org/cinnamon/ScreenSaver";
        };
    };
}
