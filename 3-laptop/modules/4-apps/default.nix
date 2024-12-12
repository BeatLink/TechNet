{ config, lib, pkgs, ... }:
{
    imports = [     
        ./comms
        ./core
        ./fun
        ./programming
        ./system
        ./technet
        ./tools
    ];
}
