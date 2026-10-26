# X-Backups ##########################################################################################################################################
#
# The borg web platform that takes over X-Monitor's borg monitors. It runs beside them for now, watching the same repositories with the same
# settings, so the two can be compared before X-Monitor's borg plugin is removed (task 16 in X-Backups' todo.md).
#
# It reaches every repository the way X-Monitor's SSH fallback does: it logs into the host borg runs on as `x-monitor-access` with X-Monitor's key,
# and runs borg there under that account's scoped sudo. Each passphrase is read on that host by `passphrase_command`, so none reaches Heimdall.
#
# The login is X-Monitor's dashboard password, hashed into /run at each start, so there is no second password to keep.
#
{
    config,
    inputs,
    pkgs,
    ...
}:
let
    port = 7710;
    hashDir = "/run/x-backups-auth";

    # Settings shared by every repository, as in X-Monitor's `borgBackup`.
    borgBackup = {
        ssh_user = "x-monitor-access";
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
        job_lock = "/run/x-monitor-borg.lock"; # X-Monitor's lock, so the two never run jobs on one host at once
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
        source_paths = [ "/Storage/System" ];
        canary_path = "/Storage/System/.vigil-canary";
        keep_hourly = 24;
        keep_daily = 7;
        keep_weekly = 4;
        keep_monthly = 12;
        keep_yearly = 3;
        skip_while_active = [ "gamemode-quiet.service" ];
    };

    # Odin's Vorta profiles, unlocked with Vorta's own passphrase.
    vortaBackup = borgBackup // {
        host = "odin.technet";
        interval = "1h";
        passphrase_command = "cat /run/secrets/vorta_backup_passphrase";
        source_paths = [ "/Storage" ];
        exclude = config.backup-excludes.patterns ++ [ "pf:/Storage/System" ];
        archive_prefix = "odin";
        canary_path = "/Storage/Files/.vigil-canary";
        prune_match = "Odin-*";
        keep_within = "6H";
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

    services.x-backups = {
        enable = true;
        inherit port;
        passwordHashFile = "${hashDir}/password-hash";
        sshKeyFile = config.sops.secrets.x_monitor_ssh_key.path;

        repositories = {
            heimdall-on-disk = serverBackup // onDisk // { repo = "/Storage/Files/Backups/Server/Borgmatic"; };
            heimdall-ragnarok =
                serverBackup
                // remote
                // {
                    repo = "ssh://borg@ragnarok.technet/Storage/Backups/Server/Borgmatic";
                    ssh_key = "/run/secrets/borg_repo_ssh_key"; # Heimdall's own borg key, which is all the repo server authorizes
                };

            odin-vorta-on-disk = vortaBackup // {
                timeout = "5m";
                repo = "/Storage/Files/Backups/Laptop/Vorta";
                keep_hourly = 12;
                keep_daily = 3;
            };
            odin-vorta-heimdall =
                vortaBackup
                // remote
                // {
                    repo = "ssh://borg@heimdall.technet/Storage/Files/Backups/Laptop/Vorta";
                    ssh_key = "/run/secrets/vorta_ssh_key"; # Odin's Vorta key, the one Vorta itself authenticates with
                    keep_hourly = 12;
                    keep_daily = 3;
                };
            odin-vorta-ragnarok =
                vortaBackup
                // remote
                // {
                    repo = "ssh://borg@ragnarok.technet/Storage/Backups/Laptop/Vorta";
                    ssh_key = "/run/secrets/vorta_ssh_key";
                    keep_hourly = 24;
                    keep_daily = 30;
                    keep_weekly = 8;
                    keep_monthly = 24;
                    keep_yearly = 3;
                };

            odin-borgmatic-on-disk = laptopBackup // onDisk // { repo = "/Storage/Files/Backups/Laptop/Borgmatic"; };
            odin-borgmatic-heimdall =
                laptopBackup
                // remote
                // {
                    repo = "ssh://borg@heimdall.technet/Storage/Files/Backups/Laptop/Borgmatic";
                    ssh_key = "/run/secrets/borg_repo_ssh_key"; # Odin's own borg key
                };
            odin-borgmatic-ragnarok =
                laptopBackup
                // remote
                // {
                    repo = "ssh://borg@ragnarok.technet/Storage/Backups/Laptop/Borgmatic";
                    ssh_key = "/run/secrets/borg_repo_ssh_key";
                };
        };
    };

    # Hashes X-Monitor's dashboard password on stdin, so it never reaches argv, a log or the Nix store.
    systemd.services.x-backups-password-hash = {
        description = "Hash X-Monitor's dashboard password for X-Backups";
        requiredBy = [ "x-backups.service" ];
        before = [ "x-backups.service" ];
        partOf = [ "x-backups.service" ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            RuntimeDirectory = baseNameOf hashDir;
            RuntimeDirectoryMode = "0700";
            RuntimeDirectoryPreserve = true;
            LoadCredential = [ "password:${config.sops.secrets.x_monitor_dashboard_password.path}" ];
        };
        script = ''
            ${pkgs.nodejs_24}/bin/node ${config.services.x-backups.package}/lib/x-backups/server/hash_password.ts ${hashDir}/password-hash \
                < "$CREDENTIALS_DIRECTORY/password"
        '';
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
