# Htop
#
# A terminal based system monitor
#
# Every host imports this, so opting out is an option rather than a missing
# import: 0-common is composed into all four configurations and dropping the
# import here would take htop off all of them. Thor sets this false in
# 5-phone/1-system/4-software.nix.

{ config, lib, pkgs, ... }:
{
    options.technet.htop.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install htop, the terminal system monitor.";
    };

    config = lib.mkIf config.technet.htop.enable {
        environment.systemPackages = [ pkgs.htop ];
    };
}
