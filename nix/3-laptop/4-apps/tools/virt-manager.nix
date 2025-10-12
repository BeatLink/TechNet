{
    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;
    environment.persistence."/Storage/Apps/System/Virt-Manager/system" = {
        directories = [

            {
                directory = "/etc/libvirt";
                user = "root";
                group = "root";
                mode = "u=rwx,g=rwx,o=";
            }

            {
                directory = "/var/lib/libvirt/";
                user = "root";
                group = "root";
                mode = "u=rwx,g=rwx,o=";
            }
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
