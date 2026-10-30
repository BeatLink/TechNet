# BorgBackup
#
# Configures the Borg Server for other devices to connect
#
# Only each source host's own borg key is authorized per repo. A
# X-Monitor-triggered backup deliberately reuses that same key rather than one of
# X-Monitor's own: X-Monitor logs into the source host as `x-monitor-access` and runs
# `borg create` there, and borg then authenticates here as the host always has.
# X-Monitor therefore triggers the host's backup instead of performing its own, and
# never holds write credentials to a backup repository.
#
{
    services.borgbackup.repos = {
        laptop-borgmatic = {
            authorizedKeys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDhnn5URZ/2Dx4yFz4E2vfKhQGViGSDRgSixehg+wUXj odin-borg-repo-borgmatic"
            ];
            path = "/Storage/Files/Backups/Laptop/Borgmatic";
            group = "borg";
        };
    };

    systemd.tmpfiles.settings."Borg"."/Storage/Files/Backups/Laptop".Z = {
        user = "borg";
        group = "borg";
        mode = "0750";
    };

}
