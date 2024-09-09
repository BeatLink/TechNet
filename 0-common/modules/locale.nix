# Language and Time -------------------------------------------------------------------------------------------------------------------
{ config, lib, pkgs, modulesPath, ... }: 
{
    time.timeZone = "America/Jamaica";                                  # Sets time zone.
    i18n.defaultLocale = "en_US.UTF-8";                                 # Sets locale.
}
