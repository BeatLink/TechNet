# Wget
#
# Download Manager                                                
#

{ pkgs, ... }:
{
    environment.systemPackages = with pkgs; [ wget];
}
