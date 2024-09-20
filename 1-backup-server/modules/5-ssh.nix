# SSH #####################################################################################################################################
#
# Adds the SSH Client key
#
###########################################################################################################################################

{ config, lib, pkgs, ... }: 
{
    users.users."beatlink".openssh.authorizedKeys.keys = [                          # Sets the SSH key for the user
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIUA2I5q9iig3vW8LWuyqVHW+quis+fGXGunNe8TqXhi beatlink@backup-server"
    ]; 
}
