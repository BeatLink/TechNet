# Root Account ######################################################################################################################################
# 
# Configures the root account
#
#####################################################################################################################################################

{
    users.users.root.hashedPassword = "!";                                      # Disables Root Account Password Login
    nix.settings.trusted-users = [ "root" ];                                    # Sets the Root Account as trusted for nix updates
    home-manager.users.root = {
        imports = [ ];
        home = {
            username = "root";
            homeDirectory = "/root";
            stateVersion = "24.11";                                             # Dont change unless reinstalled.
            sessionVariables = {
                EDITOR = "nano";
            };
        };
    };

}