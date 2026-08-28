# Backup Server ######################################################################################################################################
#
# The Rock64 SBC that holds the network's backups, off site and reachable over WireGuard.
#

{
    technet.secrets.directory = "1-backup-server";

    imports = [
        ./1-system
        ./3-services
    ];
}
