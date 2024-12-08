{ config, lib, pkgs, ... }:
{
    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;
    home-manager.users.beatlink = {
        dconf = {
            enable = true;
            settings = {
                "org/virt-manager/virt-manager/connections" = {
                    autoconnect = ["qemu:///system"];
                    uris = ["qemu:///system"];
                };
            };
        };
    };
}