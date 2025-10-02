# Boot Loader
#
# This section manages misc boot settings
#

{
    boot = {
        loader.efi.canTouchEfiVariables = false; # Leaves Tow-Boot alone
        kernelParams = [
            #"console=tty1"
            #"console=ttyS2,115200n8"
        ];
    };
}