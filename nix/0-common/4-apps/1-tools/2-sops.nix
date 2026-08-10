# SOPS ###############################################################################################################################################
#
# Credential management scheme for TechNet's flake.
#

{ pkgs, ... }:
{
    sops.age.sshKeyPaths = [ "/persistent/etc/ssh/ssh_host_ed25519_key" ]; # The host key only survives the impermanence rollback under /persistent
    environment.systemPackages = with pkgs; [ sops ];
}
