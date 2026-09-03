{
    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;
    environment.persistence."/Storage/System/LibVirt" = {
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
    # libvirt's secrets key is encrypted to this host key; a root wipe without it leaves libvirtd failing at CREDENTIALS
    environment.persistence."/persistent".files = [ "/var/lib/systemd/credential.secret" ];
    home-manager.users.beatlink = {
        home.persistence."/Storage/Apps/System/Virt-Manager" = {

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
