# Borgmatic
#
# This handles backing up my server's docker files to my laptop and to my backup server
#

{
    pkgs,
    config,
    inputs,
    ...
}:
{
    sops.secrets.borg_repo_encryption_key.sopsFile = "${inputs.self}/secrets/3-laptop.yaml";
    sops.secrets.borg_repo_ssh_key.sopsFile = "${inputs.self}/secrets/3-laptop.yaml";
    services.borgmatic = {
        enable = true;
        settings = {
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

            # Repositories
            repositories = [
                {
                    label = "On Disk Backup";
                    path = "/Storage/Files/Backups/Laptop/Borgmatic";
                }
                {
                    label = "Heimdall Backup";
                    path = "ssh://borg@heimdall.technet/Storage/Backups/Laptop/Borgmatic";
                }
                {
                    label = "Ragnarok Backup";
                    path = "ssh://borg@ragnarok.technet/Storage/Backups/Laptop/Borgmatic";
                }
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
                        "${pkgs.iputils}/bin/ping -q -c heimdall.technet > /dev/null || exit 75"
                        "${pkgs.iputils}/bin/ping -q -c 1 ragnarok.technet > /dev/null || exit 75"
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
                    frequency = "2 weeks";
                }
                {
                    name = "data";
                    frequency = "2 weeks";
                }
                {
                    name = "extract";
                    frequency = "2 weeks";
                }
            ];

            # Notifications
            uptime_kuma = {
                push_url = "https://uptime-kuma.heimdall.technet/api/push/f7xCy2APBy";
                states = [
                    #"start"
                    "finish"
                    "fail"
                ];
            };
        };
    };
}
