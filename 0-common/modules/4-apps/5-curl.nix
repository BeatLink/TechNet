# Curl
#
# Download Manager                                                
#

{ pkgs, ... }:
{
    environment.systemPackages = with pkgs; [ curl ];
}