# BorgBackup
#
# Configures the Borg Server for other devices to connect
#

{
    services.borgbackup.repos = {
        laptop = {
            authorizedKeys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFERN9fyw16t2LvfrrZdO1CpY5ZWEolg2bY1ZF4WF2SU odin-borg-key"];
            path = "/Storage/Backups/Laptop/Vorta";
        };
        server = {
            authorizedKeys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFdCCw57/UyY1YBTjif2/bMsVDSOVurJ946fKMsBOyoI heimdall-borg-key"];
            path = "/Storage/Backups/Server/Borgmatic";
        };
    };
}
