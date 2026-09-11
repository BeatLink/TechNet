# Borgmatic
#
# Backs up the server's service data to an on-disk repo and to the backup server, split into two
# configurations so an unreachable Ragnarok cannot cancel the local copy as well.
#

{
    pkgs,
    config,
    ...
}:
let
    commonSettings = {
        # Sources
        source_directories = [
            "/Storage/Services"
        ];
        # Excludes
        exclude_patterns = [
            "/Storage/Files/Backups/Server"
        ];
        exclude_if_present = [
            ".nobackup"
            ".stversions"
            ".thumbnails"
        ];

        encryption_passcommand = "cat " + config.sops.secrets.borg_repo_encryption_key.path;
        ssh_command = "ssh -i " + config.sops.secrets.borg_repo_ssh_key.path;

        # Backup Settings
        compression = "lz4";
        archive_name_format = "backup-{now}";
        relocated_repo_access_is_ok = true;
        # Create repo files group-readable (0640/0750) so the `borg` group —
        # which the Vigil monitor account belongs to — can read the on-disk
        # repo for backup-health checks. Borgmatic passes this to borg's
        # --umask (local repo only); the remote Ragnarok repo is already
        # group-accessible via the borg server.
        umask = 0027;

        # Retention
        keep_hourly = 6;
        keep_daily = 7;
        keep_weekly = 4;
        keep_monthly = 3;
        keep_yearly = 1;

        commands = [
            {
                after = "action";
                when = [ "create" ];
                states = [ "finish" ];
                run = [
                    "echo 'Backup created.'"
                ];
            }
            {
                after = "error";
                run = [
                    "echo 'Error occurred during a Borgmatic action.'"
                ];
            }
        ];

        # Consistency Checks
        # Periodic rather than every run: checking on each of the eight daily runs left borgmatic working for 2h21m at a stretch.
        checks = [
            {
                name = "repository";
                frequency = "1 week";
            }
            {
                name = "archives";
                frequency = "1 week";
            }
            {
                name = "extract";
                frequency = "1 month";
            }
            {
                name = "data";
                frequency = "1 month";
            }
        ];
    };
in
{
    sops.secrets.borg_repo_encryption_key.sopsFile = "${config.technet.secrets.path}/borgmatic.yaml";
    sops.secrets.borg_repo_ssh_key.sopsFile = "${config.technet.secrets.path}/borgmatic.yaml";
    services.borgmatic = {
        enable = true;
        configurations = {
            local = commonSettings // {
                repositories = [
                    {
                        label = "On Disk Backup";
                        path = "/Storage/Files/Backups/Server/Borgmatic";
                    }
                ];
            };
            remote = commonSettings // {
                repositories = [
                    {
                        label = "Backup Server";
                        path = "ssh://borg@ragnarok.technet/Storage/Backups/Server/Borgmatic";
                    }
                ];
                # Exit 75 is borgmatic's soft failure, which skips this configuration alone and leaves the local one to run.
                commands = commonSettings.commands ++ [
                    {
                        before = "action";
                        when = [ "create" ];
                        run = [
                            "${pkgs.iputils}/bin/ping -q -c 1 10.100.100.6 > /dev/null || exit 75"
                        ];
                    }
                ];
            };
        };
    };

    # Ragnarok is up only sporadically, so the remote copy needs repeated attempts rather than one nightly window.
    # The empty first entry clears the OnCalendar=daily shipped in borgmatic's own timer, which a drop-in would otherwise append to.
    systemd.timers.borgmatic.timerConfig.OnCalendar = [
        ""
        "*-*-* 00/3:00:00"
    ];

    # Backups are throughput jobs with no deadline, so they should yield to
    # anything interactive. Reading /Storage on a 2-disk HDD mirror otherwise
    # saturates the pool for the length of the run and blocks txg_sync for
    # minutes at a time, stalling every other service on the box.
    #
    # IOSchedulingClass=idle only issues I/O when nothing else wants the disk,
    # and IOWeight covers the cgroup path (borg spawns children, and weights are
    # inherited by the whole unit cgroup where a per-process ionice would not
    # be). Both depend on the data disks running BFQ — see 3-filesystem.nix.
    # Nice keeps the compression threads off the CPU backs of foreground work.
    # borgmatic ships its own unit file, which NixOS symlinks in as the base unit
    # and layers these on top as a drop-in; the drop-in wins, so this relaxes the
    # packaged best-effort/7 to genuine idle.
    systemd.services.borgmatic.serviceConfig = {
        Nice = 19;
        IOSchedulingClass = "idle";
        IOSchedulingPriority = 7;
        IOWeight = 10;
        CPUWeight = 10;
    };

    # borgmatic runs as root, so the on-disk repo is created root-owned and
    # (before `umask` above) 0700 — unreadable by the Vigil monitor account.
    # Grant the `borg` group read+traverse so Vigil (a member of `borg`) can
    # read the repo for backup-health checks. `umask` keeps *new* files
    # group-readable; this activation step relaxes the group and any files that
    # predate it, using `g+rX` so directories get +x for traversal while data
    # files get only +r (never +x).
    systemd.tmpfiles.settings."Borgmatic"."/Storage/Files/Backups/Server/Borgmatic".d = {
        user = "root";
        group = "borg";
        mode = "0750";
    };
    system.activationScripts.borgmaticRepoGroupRead = ''
        if [ -d /Storage/Files/Backups/Server/Borgmatic ]; then
            chgrp -R borg /Storage/Files/Backups/Server/Borgmatic || true
            chmod -R g+rX  /Storage/Files/Backups/Server/Borgmatic || true
        fi
    '';
}
