# UEFI ###############################################################################################################################################
#
# Whether the boot loader may write EFI variables.
#

{ ... }:
{
    boot.loader.efi.canTouchEfiVariables = false; # Tow-Boot on the phone and the Acer's firmware under Ragnarok break if written to; only the laptop overrides this
}
