# Initrd SSH ##########################################################################################################################
# Enables SSH in Boot for Remote LUKS Unlock
#######################################################################################################################################
{ config, lib, pkgs, ... }:{
    boot.initrd.network.ssh.hostKeys = [
        "/persistent/etc/ssh/ssh_initrd_host_ed25519_key"
    ];
    services.openssh.hostKeys = [
        { 
            type = "ed25519"; 
            path = "/persistent/etc/ssh/ssh_host_ed25519_key"; 
        }
    ];
}






