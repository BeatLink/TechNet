# Borgmatic
#
# This handles backing up my server's docker files to my laptop and to my backup server
#

{ pkgs, config, inputs, ... }: 
{
    sops.secrets.borg_repo_encryption_key.sopsFile = "${inputs.self}/secrets/2-server.yaml";
    sops.secrets.borg_repo_ssh_key.sopsFile = "${inputs.self}/secrets/2-server.yaml";
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
                    path = "ssh://borg@10.100.100.6/Storage/Backups/Server/Borgmatic";
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
                    name = "data";
                    frequency = "always";
                }
                {
                    name = "extract";
                    frequency = "always";
                } 
            ];
            check_last = 3;

            # Notifications
            uptime_kuma = {
                push_url = "http://uptime-kuma.heimdall.technet/api/push/nDXOzelHhZ";
                states = [
                    #"start"
                    "finish"
                    "fail"
                ];
            };
        };
    };
}