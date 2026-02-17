# Enables Compressed Swap in RAM
{
    zramSwap.enable = true;
    boot.kernel.sysctl = {
        vm = {
            panic_on_oom = 1;
            overcommit_memory = 2;
        };
    };
}
