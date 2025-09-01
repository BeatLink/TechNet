# PCIUtils
#
# PCI Info and Utilities                                                
#

{ pkgs, ... }:
{
    environment.systemPackages = with pkgs; [ pciutils ];
}