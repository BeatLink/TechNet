# Initrd SSH ##########################################################################################################################
# Enables SSH in Boot for Remote LUKS Unlock
#######################################################################################################################################
{ config, lib, pkgs, ... }:{
    boot.initrd = {
        network.ssh = {                                             
            port = 22;
            enable = true;
            authorizedKeys = [ 
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM4GfJHxZu55mhQPpL1MqLCrS4ws/1ZUodC/QicApyGF beatlink@technet" 
            ];
            hostKeys = [
                "/persistent/etc/ssh/ssh_initrd_host_ed25519_key"
                "/persistent/etc/ssh/ssh_initrd_host_rsa_key"
            ];
        };
        systemd.users.root.shell = "/bin/systemd-tty-ask-password-agent";
    };
    environment.persistence."/persistent".files = [
        { file = "/etc/ssh/ssh_host_rsa_key"; parentDirectory = { mode = "0755"; }; }
        { file = "/etc/ssh/ssh_host_ed25519_key"; parentDirectory = { mode = "0755"; }; }
    ];
}






