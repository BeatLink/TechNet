# BorgBackup
#
# Configures the Borg Server for other devices to connect
#
# Only each source host's own borg key is authorized per repo. A
# Vigil-triggered backup deliberately reuses that same key rather than one of
# Vigil's own: Vigil logs into the source host as `vigil-access` and runs
# `borg create` there, and borg then authenticates here as the host always has.
# Vigil therefore triggers the host's backup instead of performing its own, and
# never holds write credentials to a backup repository.
#
{
    services.borgbackup.repos = {
        laptop-vorta = {
            authorizedKeys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFERN9fyw16t2LvfrrZdO1CpY5ZWEolg2bY1ZF4WF2SU odin-borg-key"
            ];
            path = "/Storage/Backups/Laptop/Vorta";
        };
        laptop-borgmatic = {
            authorizedKeys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDhnn5URZ/2Dx4yFz4E2vfKhQGViGSDRgSixehg+wUXj odin-borg-repo-borgmatic"
            ];
            path = "/Storage/Backups/Laptop/Borgmatic";
        };
        server = {
            authorizedKeys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFdCCw57/UyY1YBTjif2/bMsVDSOVurJ946fKMsBOyoI heimdall-borg-key"
            ];
            path = "/Storage/Backups/Server/Borgmatic";
        };
    };
}
