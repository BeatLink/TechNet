# SSH #####################################################################################################################################
#
# Configures SSH for remote access and file transfers
#
###########################################################################################################################################

{ config, lib, pkgs, modulesPath, ... }: 
{
    services.openssh = {                                                # This is needed to solve problems with SSH permissions 
        hostKeys = [
            { 
                type = "ed25519"; 
                path = "/persistent/etc/ssh/ssh_host_ed25519_key"; 
            }
        ];
    };
}


