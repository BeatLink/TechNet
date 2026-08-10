# Reboot On Panic ####################################################################################################################################
#
# OOM raises a panic, the panic reboots ten seconds later, and the kernelParam covers panics that hit before sysctls are applied.
#

{
    boot = {
        kernelParams = [ "panic=10" ];
        kernel.sysctl = {
            "kernel.panic" = 10;
            "vm.panic_on_oom" = 1;
        };
    };
}
