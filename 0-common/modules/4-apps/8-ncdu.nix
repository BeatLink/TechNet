# ncdu
#
# A terminal based disk usage monitor
#

{ pkgs, ... }:
{
    environment.systemPackages = with pkgs; [ ncdu ];
}
