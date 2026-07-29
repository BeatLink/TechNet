# Borgmatic
#
# This handles backing up my server's software files to my laptop and to my backup server
#

{
    pkgs,
    config,
    inputs,
    ...
}:
{
    sops.secrets.borg_repo_encryption_key.sopsFile = "${inputs.self}/secrets/2-server/borgmatic.yaml";
    sops.secrets.borg_repo_ssh_key.sopsFile = "${inputs.self}/secrets/2-server/borgmatic.yaml";
    services.borgmatic = {
        enable = true;
        settings = {
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

            # Repositories
            repositories = [
                {
                    label = "On Disk Backup";
                    path = "/Storage/Files/Backups/Server/Borgmatic";
                }
                {
                    label = "Backup Server";
                    path = "ssh://borg@ragnarok.technet/Storage/Backups/Server/Borgmatic";
                }
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
                    before = "action";
                    when = [ "create" ];
                    run = [
                        "echo 'Starting a backup job.'"
                        "${pkgs.iputils}/bin/ping -q -c 1 10.100.100.6 > /dev/null || exit 75"
                    ];
                }
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
            checks = [
                {
                    name = "repository";
                    frequency = "always";
                }
                {
                    name = "archives";
                    frequency = "always";
                }
                {
                    name = "extract";
                    frequency = "1 day";
                }
                {
                    name = "data";
                    frequency = "1 month";
                }
            ];
        };
    };

    # Backups are throughput jobs with no deadline, so they should yield to
    # anything interactive. Reading /Storage on a 2-disk HDD mirror otherwise
    # saturates the pool for the length of the run and blocks txg_sync for
    # minutes at a time, stalling every other service on the box.
    #
    # IOSchedulingClass=idle only issues I/O when nothing else wants the disk,
    # and IOWeight covers the cgroup path (borg spawns children, and weights are
    # inherited by the whole unit cgroup where a per-process ionice would not
    # be). Both depend on the data disks running BFQ — see 2-data-drive.nix.
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
    systemd.tmpfiles.rules = [
        "d /Storage/Files/Backups/Server/Borgmatic 0750 root borg - -"
    ];
    system.activationScripts.borgmaticRepoGroupRead = ''
        if [ -d /Storage/Files/Backups/Server/Borgmatic ]; then
            chgrp -R borg /Storage/Files/Backups/Server/Borgmatic || true
            chmod -R g+rX  /Storage/Files/Backups/Server/Borgmatic || true
        fi
    '';
}
