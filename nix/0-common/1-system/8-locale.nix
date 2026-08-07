# Language and Time ##################################################################################################################################

{
    time.timeZone = "America/Jamaica";
    services.timesyncd.enable = true;
    i18n.defaultLocale = "en_US.UTF-8";
    services.xserver.xkb = {
        layout = "us";
        variant = "";
    };
}
