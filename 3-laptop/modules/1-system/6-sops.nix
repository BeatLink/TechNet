# SOPS #####################################################################################################################################
#
# Configures the path to the SSH Host Key for credential decryption
#
###########################################################################################################################################

{ config, lib, pkgs, modulesPath, ... }: 
{
    sops.age.sshKeyPaths = [ "/persistent/etc/ssh/ssh_host_ed25519_key" ];     # Sets the sops ssh key to persistent
    environment.systemPackages = with pkgs; [ sops ];
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home.persistence."/Storage/Apps/System/SOPS" = {
            files = [
                ".config/sops/age/keys.txt"
            ];
            allowOther = true;
        };
    };
}

