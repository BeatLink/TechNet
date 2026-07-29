{ inputs, ... }:
{
    technet.tang.server = {
        enable = true;
        sopsFile = "${inputs.self}/secrets/3-laptop/tang.yaml";
        screensaver = {
            dbusName = "org.cinnamon.ScreenSaver";
            objectPath = "/org/cinnamon/ScreenSaver";
        };
    };
}
