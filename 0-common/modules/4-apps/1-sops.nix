# SOPS
#
# Credential Management Scheme for TechNet's Flake                                                
#

{ pkgs, ... }:
{
    sops.age.sshKeyPaths = [ "/persistent/etc/ssh/ssh_host_ed25519_key" ];     # Sets the sops ssh key to persistent
    environment.systemPackages = with pkgs; [ sops ];
}
