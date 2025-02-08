# Users ###################################################################################################################################
#
# Configures the user accounts for devices in the TechNet
#
###########################################################################################################################################

{
    users.mutableUsers = false;                                                 # Have users be managed by NixOS Config File
    security.sudo.wheelNeedsPassword = false;                                   # Removes the need for entering passwords for sudo
    home-manager.backupFileExtension = "hmbackup";                              # Sets the Home Manager Backup File Extension
    imports = [                                       
        ./1-root.nix
        ./2-beatlink.nix
    ];
 }
