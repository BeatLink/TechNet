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
        extraConfig = ''
            MaxStartups 1                                               # Limits number of concurrent connection attempts
            AllowTcpForwarding yes
            X11Forwarding no
            AllowAgentForwarding no
            AllowStreamLocalForwarding no
            AuthenticationMethods publickey
        '';
    };
}