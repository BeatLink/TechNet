{ config, lib, pkgs, ... }:
{
    imports = [     
        ./comms
        ./core
        #./fun
        ./system
        ./tools
    ];
}
