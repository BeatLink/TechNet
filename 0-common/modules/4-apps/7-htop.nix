# Htop
#
# A terminal based system monitor                                                
#

{ pkgs, ... }:
{
    environment.systemPackages = with pkgs; [ htop ];
}
