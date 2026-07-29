{ inputs, ... }:
{
    technet.tang.server = {
        enable = true;
        persistenceRoot = "/Storage/System/Tang";
        sopsFile = "${inputs.self}/secrets/3-laptop/tang.yaml";
        screensaver = {
            dbusName = "org.cinnamon.ScreenSaver";
            objectPath = "/org/cinnamon/ScreenSaver";
        };
    };
}
