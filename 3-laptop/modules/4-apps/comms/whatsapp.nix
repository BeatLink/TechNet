{ config, pkgs, ... }: 
{
    home-manager.users.beatlink.xdg.desktopEntries = {
        "whatsapp-private" = {
            name = "WhatsApp (Private)";
            comment = "";
            exec = "firefox \"ext+container:name=Private&url=https://web.whatsapp.com\"";
            terminal = false;
            type = "Application";
            prefersNonDefaultGPU = false;
            icon = "whatsapp";
            categories = ["Network" "InstantMessaging"];
        };
        "whatsapp" = {
            name = "WhatsApp";
            comment = "";
            exec = "firefox https://web.whatsapp.com";
            terminal = false;
            type = "Application";
            prefersNonDefaultGPU = false;
            icon = "whatsapp";
            categories = ["Network" "InstantMessaging"];
        };
    };
}