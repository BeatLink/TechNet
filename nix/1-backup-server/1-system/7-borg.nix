# BorgBackup
#
# Configures the Borg Server for other devices to connect
#
# Two kinds of client key are authorized per repo:
#   * the `odin-borg-*` / `heimdall-borg-key` keys, used by Vorta/borgmatic on
#     the source hosts for the scheduled backups that normally populate these
#     repos;
#   * the `vigil@technet` key, used by Vigil's manually-triggered "Run Backup"
#     action. Vigil logs into the *source* host as `vigil-access` and runs
#     `borg create` there against an ssh:// URL pointing here, so the key that
#     must be authorized is Vigil's, not the source host's own borg key.
#
# Note this grants Vigil write access to the backup repositories: `borg create`
# is a write, and the same channel can prune or delete. That is inherent to
# triggering backups from Vigil, and is the trade-off accepted for it.
#
{
    services.borgbackup.repos = {
        laptop-vorta = {
            authorizedKeys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFERN9fyw16t2LvfrrZdO1CpY5ZWEolg2bY1ZF4WF2SU odin-borg-key"
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID6oDtIndxb2aJJFhl3+xU+4nuVUQQrzcWOLX+RslJU/ vigil@technet"
            ];
            path = "/Storage/Backups/Laptop/Vorta";
        };
        laptop-borgmatic = {
            authorizedKeys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDhnn5URZ/2Dx4yFz4E2vfKhQGViGSDRgSixehg+wUXj odin-borg-repo-borgmatic"
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID6oDtIndxb2aJJFhl3+xU+4nuVUQQrzcWOLX+RslJU/ vigil@technet"
            ];
            path = "/Storage/Backups/Laptop/Borgmatic";
        };
        server = {
            authorizedKeys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFdCCw57/UyY1YBTjif2/bMsVDSOVurJ946fKMsBOyoI heimdall-borg-key"
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID6oDtIndxb2aJJFhl3+xU+4nuVUQQrzcWOLX+RslJU/ vigil@technet"
            ];
            path = "/Storage/Backups/Server/Borgmatic";
        };
    };
}
