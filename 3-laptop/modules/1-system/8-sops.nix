# SSH #####################################################################################################################################
#
# Configures SSH for remote access and file transfers
#
###########################################################################################################################################

{ config, lib, pkgs, modulesPath, ... }: 
{
    sops.age.sshKeyPaths = [ "/persistent/etc/ssh/ssh_host_ed25519_key" ];     # Sets the sops ssh key to persistent
}