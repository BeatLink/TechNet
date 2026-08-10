# UEFI ###############################################################################################################################################
#
# Whether the boot loader may write EFI variables.
#

{ ... }:
{
    boot.loader.efi.canTouchEfiVariables = false; # Tow-Boot on the ARM boards and Heimdall's firmware break if written to; only the laptop overrides this
}
