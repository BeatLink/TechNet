# FastFetch
#
# A terminal based system info tool similar to neofetch                                                
#

{ pkgs, ... }:
{
    environment.systemPackages = with pkgs; [ fastfetch ];
}
