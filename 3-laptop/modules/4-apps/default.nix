{ config, lib, pkgs, ... }:
{
    imports = [     
        ./comms
        ./core
        ./fun
        ./programming
        ./system
        ./tools
    ];
}
