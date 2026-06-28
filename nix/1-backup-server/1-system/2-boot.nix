# Boot Loader
#
# This section manages misc boot settings
#

{
    boot = {
        loader.efi.canTouchEfiVariables = false;                            # Leaves Tow-Boot alone
        initrd.kernelModules = [ "simpledrm" ];                             # Use Tow-Boot framebuffer for early console output
        kernelParams =  [
            "console=tty1"
            "console=ttyS2,115200n8"
        ];
    };
}