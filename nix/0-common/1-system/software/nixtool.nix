# Nixtool ############################################################################################################################################
#
# Provides the programs.nixtool module that the laptop configures.
#

{ inputs, ... }:
{
    imports = [ inputs.nixtool.nixosModules.default ];
}
