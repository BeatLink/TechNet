# BorgBackup
#
# Configures the Borg Server for other devices to connect
#

{
    services.borgbackup.repos = {
        laptop = {
            authorizedKeys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFERN9fyw16t2LvfrrZdO1CpY5ZWEolg2bY1ZF4WF2SU odin-borg-key"
            ];
            path = "/Storage/Files/Backups/Laptop/Vorta";
            group = "beatlink";
        };
    };
}
