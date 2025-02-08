# Root Account ######################################################################################################################################
# 
# Configures the root account
#
#####################################################################################################################################################

{
    users.users.root.hashedPassword = "!";                                      # Disables Root Account Password Login
    nix.settings.trusted-users = [ "root" ];                                    # Sets the Root Account as trusted for nix updates
}