# Laptop Configuration
#
# TODO: Add Notes
#

{
    technet.secrets.directory = "5-phone";
    technet.waypipe.enable = true;
    technet.activitywatch = {
        monitor = true;
        transport = "rsync"; # Thor is not a Syncthing peer
    };

    imports = [
        ./1-system
        ./2-users.nix
        ./3-apps
    ];
}
