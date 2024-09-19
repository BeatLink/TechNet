# SSH #####################################################################################################################################
#
# SSH will be the primary way to remotely access devices.
#
# It will provide the following services:  
#   - Remote Access  
#   - File Access through SFTP
#
###########################################################################################################################################

{ config, lib, pkgs, modulesPath, ... }: 
{
    services.openssh = {
        enable = true;                                                  # Enable the OpenSSH daemon.
        allowSFTP = true;                                               # Allows file transfers over SSH
        settings = {
            PasswordAuthentication = false;                             # Disables password based login
            KbdInteractiveAuthentication = false;                       # Disables keyboard based login
            PermitRootLogin = "no";                                     # Disables root login
        };
        extraConfig = [
            "MaxStartups 1"
        ]
    };
    systemd.tmpfiles.rules = [                                          # Sets permissions for SSH folder 
        "d /etc 0755 root root"
        "d /etc/ssh 0755 root root"
    ];
}