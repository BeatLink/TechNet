{
    boot = {
        kernelParams = [ "panic=10" ];
        kernel.sysctl = {
            kernel.panic = 10;
        };
    };

}
