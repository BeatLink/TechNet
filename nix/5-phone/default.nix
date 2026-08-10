# Laptop Configuration
#
# TODO: Add Notes
#

{
    technet.secrets.directory = "5-phone";
    technet.pinephoneCache.enable = true;
    technet.waypipe.enable = true;

    imports = [
        ../0-common/desktop
        ./1-system
        ./2-users.nix
        ./3-apps
    ];
}
