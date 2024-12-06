# SSH #####################################################################################################################################
#
# Configures SSH for remote access and file transfers
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
            challengeResponseAuthentication = false;
            PermitRootLogin = "no";                                     # Disables root login
        };
    };
}