# Tree
#
# Terminal File Lister as Trees                                                
#

{ pkgs, ... }:
{
    environment.systemPackages = with pkgs; [ tree ];
}
