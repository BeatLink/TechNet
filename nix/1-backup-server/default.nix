# Backup Server
#
# This provides the configuration for the Rock64 SBC Backup Server
#
{
    technet.secrets.directory = "1-backup-server";

    imports = [
        ./1-system
    ];
}
