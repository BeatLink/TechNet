# Laptop Configuration
#
# TODO: Add Notes
#

{
    technet.secrets.directory = "5-phone";

    imports = [
        ./1-system
        ./2-users.nix
        ./3-apps
    ];
}
