# Borgmatic ###########################################################################################################################
# This handles backing up my server's docker files to my laptop and to my backup server
#######################################################################################################################################
{ config, lib, pkgs, modulesPath, ... }: 
{
    services.borgmatic = {
        enable = true;
        configurations = {
            server-backups = {
                location = {
                    source_directories = [
                        "/Storage/Services"
                    ];
                    exclude_patterns = [
                        "/Storage/Files/Backups/Server"
                    ];
                    exclude_if_present = [
                        ".nobackup"
                        ".stversions"
                        ".thumbnails"
                    ];
                    repositories = [
                        "/Storage/Files/Backups/Server/Borgmatic"
                        "ssh://beatlink@10.100.100.2/media/beatlink/Storage/Files/Backups/Server/Borgmatic"
                    ];
                    one_file_system = true;
                };
                storage = {
                    compression = "lz4";
                    archive_name_format = "backup-{now}";
                    relocated_repo_access_is_ok = true;
                };
                retention = {
                    keep_hourly = 1;
                    keep_daily = 1;
                    keep_weekly = 1;
                    keep_monthly = 1;
                    keep_yearly = 1;
                    prefix = "backup-";
                };
                consistency = {
                    checks = [
                        "repository"
                        "archives"
                    ];
                    check_last = 3;
                    prefix = "backup-";
                };
                hooks = {
                    before_backup = [
                        "echo Starting a backup job."
                    ];
                    after_backup = [
                        "echo Backup created."
                    ];
                    on_error = [
                        "echo Error while creating a backup."
                    ];
                };
            };
        };
    };
}