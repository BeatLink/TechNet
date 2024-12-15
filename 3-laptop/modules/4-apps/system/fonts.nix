{ config, lib, pkgs, ... }:
{
    fonts.packages = with pkgs; [ 
        corefonts                                   # Microsoft Fonts
        nerdfonts                                   # Unified fonts with icons 
    ];
}
