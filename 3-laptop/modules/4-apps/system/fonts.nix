{ config, lib, pkgs, ... }:
{
    fonts.packages = with pkgs; [ 
        corefonts                                   # Microsoft Fonts
        noto-fonts
    ];
}
