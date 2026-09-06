# Borgmatic
#
# Backs up the laptop's system files to an on-disk repo and to both backup servers, split into one
# configuration per repository so an unreachable server cannot cancel the others.
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
            "/Storage/System"
        ];
        # Excludes
        exclude_patterns = [ ];
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

        # Retention
        keep_hourly = 24;
        keep_daily = 7;
        keep_weekly = 4;
        keep_monthly = 12;
        keep_yearly = 3;

        commands = [
            {
                before = "action";
                when = [ "create" ];
                run = [
                    "echo 'Starting a backup job.'"
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
        # Periodic rather than every run: the repository check alone took 17 minutes on a remote copy.
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

    # Skips one configuration when its repository host is not answering SSH, leaving the others to run.
    reachable = host: [
        {
            before = "action";
            when = [ "create" ];
            # Reads the SSH banner rather than pinging: a host can answer ICMP while its SSH transport hangs. Exit 75 is borgmatic's soft failure.
            run = [
                "${pkgs.netcat-openbsd}/bin/nc -w 5 '${host}' 22 < /dev/null | ${pkgs.gnugrep}/bin/grep -q '^SSH-' || exit 75"
            ];
        }
    ];
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
                        path = "/Storage/Files/Backups/Laptop/Borgmatic";
                    }
                ];
            };
            heimdall = commonSettings // {
                repositories = [
                    {
                        label = "Heimdall Backup";
                        path = "ssh://borg@heimdall.technet/Storage/Files/Backups/Laptop/Borgmatic";
                    }
                ];
                commands = commonSettings.commands ++ reachable "heimdall.technet";
            };
            ragnarok = commonSettings // {
                repositories = [
                    {
                        label = "Ragnarok Backup";
                        path = "ssh://borg@ragnarok.technet/Storage/Backups/Laptop/Borgmatic";
                    }
                ];
                commands = commonSettings.commands ++ reachable "ragnarok.technet";
            };
        };
    };

    # Three-hourly so a missed window is retried the same day rather than waiting for the next night.
    # The empty first entry clears the OnCalendar=daily shipped in borgmatic's own timer, which a drop-in would otherwise append to.
    systemd.timers.borgmatic.timerConfig.OnCalendar = [ "" "*-*-* 00/3:00:00" ];

    # A ceiling rather than a working limit: a measured 28-minute run spent 78s of CPU, so this binds only on a run that misbehaves.
    systemd.services.borgmatic.serviceConfig.CPUQuota = "150%";

    # The packaged unit omits CAP_DAC_OVERRIDE, so root cannot write the beatlink-owned 0700 repository directory.
    systemd.services.borgmatic.serviceConfig.CapabilityBoundingSet = [
        "CAP_DAC_READ_SEARCH"
        "CAP_DAC_OVERRIDE"
        "CAP_FOWNER"
        "CAP_NET_RAW"
    ];

    # Notifications
    #
    # Backup health is monitored by Vigil rather than pushed from here.
    # Vigil's `borg` monitors (nix/2-server/3-services/monitoring/vigil.nix,
    # "Backups" group) read each repo directly over SSH and alert when the
    # newest archive exceeds max_age. That checks the repository itself —
    # the authoritative state — instead of trusting this scheduler to
    # report its own failure, so a borgmatic unit that never runs at all
    # is still caught.
}
