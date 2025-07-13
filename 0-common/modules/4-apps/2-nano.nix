# Nano
#
# A terminal based text Editor                                                
#

{ pkgs, ... }:
{
    environment.systemPackages = with pkgs; [ nano  ];
}

