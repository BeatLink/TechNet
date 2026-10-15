# BattleTime App Builder #############################################################################################################################
#
# The VSCodium extension for building BattleTime watch apps: a palette of widgets, events and effects beside an app's source, and the app running
# in the BattleTime simulator. It builds the compiler and simulator from the BattleTime checkout the app is in, through that checkout's nix develop.
#
{ inputs, ... }:
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            programs.vscodium.profiles.default.extensions = [
                inputs.battletime.packages.${pkgs.stdenv.hostPlatform.system}.appbuilder
            ];
        };
}
