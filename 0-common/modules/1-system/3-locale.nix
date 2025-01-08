# Language and Time #######################################################################################################################
#
# Sets the language, time and locale
#
###########################################################################################################################################

{ config, lib, pkgs, modulesPath, ... }: 
{
    time.timeZone = "America/Jamaica";                                  # Sets time zone.
    i18n.defaultLocale = "en_US.UTF-8";                                 # Sets locale.
    services.xserver.xkb = {                                            # Sets the Keyboard Layout
        layout = "us";
        variant = "";
    };
}
