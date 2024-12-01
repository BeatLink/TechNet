# SSH ##########################################################################################################################
# Enables SSH 
#######################################################################################################################################
{ config, lib, pkgs, ... }:{
    environment.persistence."/persistent".files = [
        { file = "/etc/ssh/ssh_host_rsa_key"; parentDirectory = { mode = "0755"; }; }
        { file = "/etc/ssh/ssh_host_ed25519_key"; parentDirectory = { mode = "0755"; }; }
    ];
}
