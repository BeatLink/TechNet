# Reboot On Panic ####################################################################################################################################
#
# Panic reboots ten seconds later, and the kernelParam covers panics that hit before sysctls are applied.
#

{
    boot = {
        kernelParams = [ "panic=10" ];
        kernel.sysctl = {
            "kernel.panic" = 10;
        };
    };
}
