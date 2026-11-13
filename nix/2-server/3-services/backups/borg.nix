# BorgBackup
#
# Configures the Borg Server for other devices to connect
#
# Only each source host's own borg key is authorized per repo. X-Backups runs `borg create` on the source host through its agent, so borg
# authenticates here as that host, and X-Backups never holds write credentials to a backup repository.
#
{
    services.borgbackup.repos = {
        odin = {
            authorizedKeys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDhnn5URZ/2Dx4yFz4E2vfKhQGViGSDRgSixehg+wUXj odin-borg-repo-borgmatic"
            ];
            path = "/Storage/Files/Backups/Odin";
            group = "borg";
        };
    };

    systemd.tmpfiles.settings."Borg"."/Storage/Files/Backups/Odin".Z = {
        user = "borg";
        group = "borg";
        mode = "0750";
    };

}
