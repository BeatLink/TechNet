# Fonts ##############################################################################################################################################
#
# The font set every host ships.
#

{ pkgs, ... }:
{
    fonts.packages = with pkgs; [
        corefonts # Microsoft fonts
        noto-fonts
        nerd-fonts.noto
    ];
}
