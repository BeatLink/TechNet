# X-Backups ##########################################################################################################################################
#
# The borg web platform that runs and watches Heimdall's and Odin's borg backups, taking them over from X-Monitor's borg monitors, which now
# only check its health (x-monitor.nix).
#
# It reaches every repository through the X-Backups agent on the host borg runs on (x-backups-agent.nix), which signs in with the key declared under
# `hosts` and runs borg under its own scoped sudo. Each passphrase is read on that host by `passphrase_command`, so none reaches Heimdall.
#
# The login's password hash is its own, in secrets/2-server/x-backups.yaml, written by X-Backups' `npm run hash-password`.
#
{
    config,
    inputs,
    pkgs,
    ...
}:
let
    port = 7710;

    # Settings shared by every repository.
    borgBackup = {
        max_age = "1d";
        cache_dir = "/var/cache/x-monitor-borg";
        require_sudo = true;
        exclude = config.backup-excludes.patterns;
        exclude_if_present = config.backup-excludes.markers;
        exclude_caches = false;
        allow_purge = true;
        compression = "lz4";
        job_nice = 19;
        job_io_idle = true;
        inhibit_sleep = true;
        job_lock = "/run/x-monitor-borg.lock"; # Also taken by Odin's Vorta replay, so the two never run borg at once
    };

    # Heimdall's and Odin's borgmatic repositories.
    borgmaticBackup = borgBackup // {
        passphrase_command = "cat /run/secrets/borg_repo_encryption_key";
        # The sources hold nested datasets, which --one-file-system would silently leave out.
        one_file_system = false;
        archive_prefix = "backup";
        prune_after_backup = true;
        compact_after_backup = true;
        check_kinds = {
            repository = "8d";
            archives = "8d";
            extract = "32d";
            data = "32d";
        };
    };

    # When a repository's tasks run, as X-Monitor ran them: a backup every three hours, followed by a prune and a compact, a weekly check
    # of the repository and its archives on `weekday` at `hour`, and monthly extract and data checks from day `day`.
    backupTasks =
        {
            weekday,
            day,
            hour,
        }:
        {
            backup = "0 */3 * * *";
            check = [
                {
                    kind = "all";
                    schedule = "0 ${toString hour} * * ${weekday}";
                }
                {
                    kind = "extract";
                    schedule = "0 ${toString hour} ${toString day} * *";
                }
                {
                    kind = "data";
                    schedule = "0 ${toString hour} ${toString (day + 7)} * *";
                }
            ];
        };

    serverBackup = borgmaticBackup // {
        host = "heimdall.technet";
        source_paths = [
            "/Storage/Services"
            "/Storage/Apps"
            "/Storage/PhoneApps"
        ];
        canary_path = "/Storage/Services/.vigil-canary";
        keep_hourly = 6;
        keep_daily = 7;
        keep_weekly = 4;
        keep_monthly = 3;
        keep_yearly = 1;
    };

    laptopBackup = borgmaticBackup // {
        host = "odin.technet";
        # All of /Storage, which Vorta used to back up.
        source_paths = [ "/Storage" ];
        canary_path = "/Storage/System/.vigil-canary";
        keep_hourly = 24;
        keep_daily = 7;
        keep_weekly = 4;
        keep_monthly = 12;
        keep_yearly = 3;
        skip_while_active = [ "gamemode-quiet.service" ];
    };

    # Ragnarok's USB pool can take many minutes to answer, so remote repositories keep a long timeout, still under their interval.
    remote = {
        interval = "1h";
        timeout = "30m";
    };
    onDisk = {
        interval = "15m";
        timeout = "5m";
    };
in
{
    imports = [ inputs.x-backups.nixosModules.default ];

    sops.secrets.x_backups_password_hash.sopsFile = "${config.technet.secrets.path}/x-backups.yaml";

    services.x-backups = {
        enable = true;
        inherit port;
        passwordHashFile = config.sops.secrets.x_backups_password_hash.path;

        # The hosts borg runs on, each reached through its agent and named as the repositories' `host` names them.
        hosts = {
            "heimdall.technet" = {
                address = "heimdall.technet";
                agent_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKJxOrgb0apKSkjgHYctGQArLodx3hkQTS5NkO6hZdxY x-backups-agent-heimdall";
            };
            "odin.technet" = {
                address = "odin.technet";
                agent_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGKAWTL9Mk0V/yOKzGfN7Pdpxkk+hMMaCzTTH6cF1VUl x-backups-agent-odin";
            };
            # Ragnarok holds the remote repositories, which its agent can read locally
            "ragnarok.technet" = {
                address = "ragnarok.technet";
                agent_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIWwX835zk3CXBjSgi62Y8covbX0PexYRuGISUy3p23/ x-backups-agent-ragnarok";
            };
        };

        repositories = {
            heimdall-on-disk =
                serverBackup
                // onDisk
                // {
                    repo = "/Storage/Files/Backups/Server/Borgmatic";
                    tasks = backupTasks {
                        weekday = "mon";
                        day = 8;
                        hour = 4;
                    };
                };
            heimdall-ragnarok =
                serverBackup
                // remote
                // {
                    repo = "ssh://borg@ragnarok.technet/Storage/Backups/Server/Borgmatic";
                    ssh_key = "/run/secrets/borg_repo_ssh_key"; # Heimdall's own borg key, which is all the repo server authorizes
                    tasks = backupTasks {
                        weekday = "tue";
                        day = 9;
                        hour = 4;
                    };
                };


            odin-borgmatic-on-disk =
                laptopBackup
                // onDisk
                // {
                    repo = "/Storage/Files/Backups/Laptop/Borgmatic";
                    tasks = backupTasks {
                        weekday = "sun";
                        day = 2;
                        hour = 13;
                    };
                };
            odin-borgmatic-heimdall =
                laptopBackup
                // remote
                // {
                    repo = "ssh://borg@heimdall.technet/Storage/Files/Backups/Laptop/Borgmatic";
                    ssh_key = "/run/secrets/borg_repo_ssh_key"; # Odin's own borg key
                    tasks = backupTasks {
                        weekday = "sun";
                        day = 3;
                        hour = 13;
                    };
                };
            odin-borgmatic-ragnarok =
                laptopBackup
                // remote
                // {
                    repo = "ssh://borg@ragnarok.technet/Storage/Backups/Laptop/Borgmatic";
                    ssh_key = "/run/secrets/borg_repo_ssh_key";
                    # The long-term copy keeps Vorta's longer history.
                    keep_daily = 30;
                    keep_weekly = 8;
                    keep_monthly = 24;
                    tasks = backupTasks {
                        weekday = "sun";
                        day = 4;
                        hour = 13;
                    };
                };
        };
    };

    environment.persistence."/Storage/Services/X-Backups".directories = [
        "/var/lib/private/x-backups"
    ];

    # Impermanence leaves the persisted copy world-readable, exposing the job logs and archive listings to every local account
    systemd.services.x-backups.serviceConfig.ExecStartPre = [
        "+${pkgs.coreutils}/bin/chmod 0700 /Storage/Services/X-Backups"
    ];

    nginx-vhosts.x-backups = {
        domain = "backups.heimdall.technet";
        inherit port;
    };
}
