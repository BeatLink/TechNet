# Initrd SSH ##########################################################################################################################
# Enables SSH in Boot for Remote LUKS Unlock
#######################################################################################################################################
{ config, lib, pkgs, ... }:{
    boot.initrd = {
        network.ssh = {                                             
            port = 22;
            enable = true;
            authorizedKeys = [ 
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILYQ9aXy5sS9PCKopaB58c8ZA/JGOEoBLMSg4a0n4aw7 beatlink@heimdall" 
            ];
            hostKeys = [
                "/persistent/etc/ssh/ssh_initrd_host_ed25519_key"
                "/persistent/etc/ssh/ssh_initrd_host_rsa_key"
            ];
        };
        systemd.users.root.shell = "/bin/systemd-tty-ask-password-agent";
    };
    users.users."beatlink".openssh.authorizedKeys.keys = [              # Sets the SSH key for the user
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILYQ9aXy5sS9PCKopaB58c8ZA/JGOEoBLMSg4a0n4aw7 beatlink@heimdall"
    ]; 
    environment.persistence."/persistent".files = [
        { file = "/etc/ssh/ssh_host_rsa_key"; parentDirectory = { mode = "0755"; }; }
        { file = "/etc/ssh/ssh_host_ed25519_key"; parentDirectory = { mode = "0755"; }; }
    ];
}






