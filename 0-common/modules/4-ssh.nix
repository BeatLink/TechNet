# SSH ---------------------------------------------------------------------------------------------------------------------------------
{ config, lib, pkgs, modulesPath, ... }: 
{
    services.openssh = {
        enable = true;                                                  # Enable the OpenSSH daemon.
        allowSFTP = true;                                               # Allows file transfers over SSH
        settings = {
            PasswordAuthentication = true;                             # Enables password based login
            KbdInteractiveAuthentication = true;                       # Enables keyboard based login
            PermitRootLogin = "no";                                    # Disables root login
        };
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
    users.users."beatlink".openssh.authorizedKeys.keys = [              # Sets the SSH key for the user
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILYQ9aXy5sS9PCKopaB58c8ZA/JGOEoBLMSg4a0n4aw7 beatlink@heimdall"
    ]; 
    systemd.tmpfiles.rules = [                                          # Sets permissions for SSH folder 
        "d /etc 0755 root root"
        "d /etc/ssh 0755 root root"
    ];
    networking.firewall.allowedTCPPorts = [ 22 ];                       # Enables SSH in the firewall
}