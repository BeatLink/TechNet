# Language, Time and Locale ##########################################################################################################################
#
# The locale, keyboard layout and time zone shared by every host, plus the NTP client that keeps the clock honest.
#

{ lib, ... }:
{
    config = lib.mkMerge [

        # Locale #####################################################################################################################################
        {
            i18n.defaultLocale = "en_US.UTF-8";
        }

        # Keyboard Layout ############################################################################################################################
        {
            services.xserver.xkb = {
                layout = "us";
                variant = "";
            };
        }

        # Time #######################################################################################################################################
        {
            time.timeZone = "America/Jamaica";
            services.timesyncd.enable = true;
        }
    ];
}
