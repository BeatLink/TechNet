# BattleTime Companion ###############################################################################################################################
#
# The desktop companion for the PineTime running BattleTime: firmware updates, apps, and the computer's notifications, media and weather forwarded
# over Bluetooth. Ships the window (battletime-companion) and the command line tool (battletime).
#
{ inputs, ... }:
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = [
                    inputs.battletime.packages.${pkgs.stdenv.hostPlatform.system}.companion
                ];
                persistence."/Storage/Apps/TechNet/BattleTimeCompanion" = {
                    directories = [
                        ".config/BattleTime Companion"
                        ".config/battletime-companion"
                    ];
                };
            };
        };
}
