# USBUtils
#
# USB Info Utilities                                                
#

{ pkgs, ... }:
{
    environment.systemPackages = with pkgs; [ usbutils ];
}
