# NeoTime App Builder ################################################################################################################################
#
# The VSCodium extension for building NeoTime watch apps: a palette of widgets, events and effects beside an app's source, and the app running in the
# NeoTime simulator. It builds the compiler and simulator from the NeoTime checkout the app is in, through that checkout's nix develop.
#
{ inputs, ... }:
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            programs.vscodium.profiles.default.extensions = [
                inputs.neotime.packages.${pkgs.stdenv.hostPlatform.system}.appbuilder
            ];
        };
}
