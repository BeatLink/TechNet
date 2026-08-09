# Boot Loader
#
# This section manages misc boot settings
#

{ lib, ... }:
{
    boot.loader.efi.canTouchEfiVariables = lib.mkForce true;                # Allows setting boot order, UEFI settings, etc. Forced over 0-common's false
}