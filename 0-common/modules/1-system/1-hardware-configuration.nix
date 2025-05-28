{ modulesPath, ... }:
{
    imports = [ 
        (modulesPath + "/installer/scan/not-detected.nix")
    ];
    services.fstrim.enable = true;
    services.fwupd.enable = true;

}