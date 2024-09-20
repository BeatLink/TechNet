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
                "/persistent/etc/ssh/ssh_host_ed25519_key"
                "/persistent/etc/ssh/ssh_host_rsa_key"
            ];
        };
        systemd.users.root.shell = "/bin/systemd-tty-ask-password-agent";
    };
    users.users."beatlink".openssh.authorizedKeys.keys = [              # Sets the SSH key for the user
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILYQ9aXy5sS9PCKopaB58c8ZA/JGOEoBLMSg4a0n4aw7 beatlink@heimdall"
    ]; 
    services.openssh = {
        hostKeys = [
            { 
                type = "ed25519"; 
                path = "/persistent/etc/ssh/ssh_host_ed25519_key"; 
            }
            { 
                type = "rsa"; 
                bits = 4096; 
                path = "/persistent/etc/ssh/ssh_host_rsa_key"; 
            }
        ];
    };
    systemd.tmpfiles.rules = [                                          # Sets permissions for SSH folder 
        "d /etc 0755 root root"
        "d /etc/ssh 0755 root root"
    ];

}






