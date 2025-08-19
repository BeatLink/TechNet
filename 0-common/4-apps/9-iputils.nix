# IPUtils
#
# Network Info Utilities                                                
#

{ pkgs, ... }:
{
    environment.systemPackages = with pkgs; [ iputils ];
}
