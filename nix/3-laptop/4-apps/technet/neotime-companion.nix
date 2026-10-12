# NeoTime Companion ##################################################################################################################################
#
# The desktop companion for the PineTime running NeoTime: firmware updates, apps, and the computer's notifications, media and weather forwarded over
# Bluetooth. Ships the window (neotime-companion) and the command line tool (neotime).
#
{ inputs, ... }:
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = [
                    inputs.neotime-companion.packages.${pkgs.stdenv.hostPlatform.system}.default
                ];
                persistence."/Storage/Apps/TechNet/NeoTimeCompanion" = {
                    directories = [
                        ".config/NeoTime Companion"
                        ".config/neotime-companion"
                    ];
                };
            };
        };
}
