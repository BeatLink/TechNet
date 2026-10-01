# Play it Slowly #####################################################################################################################################
#
# Plays music slower or at a different pitch for practice, from the fork in /Storage/Files/Projects/Coding/PlayItSlowlyNext.
#
{ inputs, ... }:
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = [
                    inputs.playitslowly.packages.${pkgs.stdenv.hostPlatform.system}.default
                ];

                # Per-song speed, pitch and loop points live in this file, and the home rollback would otherwise blank it.
                persistence."/Storage/Apps/Fun/PlayItSlowly" = {
                    files = [
                        ".config/playitslowly.json"
                    ];
                };
            };
        };
}
