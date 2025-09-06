{
    config,
    lib,
    pkgs,
    ...
}:
{
    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;
    environment.persistence."/Storage/Apps/System/Virt-Manager/system" = {
        directories = [
            "/etc/libvirt"
            "/var/lib/libvirt/"
        ];
    };
    home-manager.users.beatlink = {
        home.persistence."/Storage/Apps/System/Virt-Manager/user" = {
            allowOther = true;
            directories = [
                ".config/virt-manager"
                ".local/share/virt-manager"
            ];
        };
        dconf = {
            enable = true;
            settings = {
                "org/virt-manager/virt-manager/connections" = {
                    autoconnect = [ "qemu:///system" ];
                    uris = [ "qemu:///system" ];
                };
            };
        };
    };
}
