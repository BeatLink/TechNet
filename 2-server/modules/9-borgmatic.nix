# Borgmatic ###########################################################################################################################
# This handles backing up my server's docker files to my laptop and to my backup server
#######################################################################################################################################
{ config, lib, pkgs, modulesPath, ... }: 
{
    services.borgmatic = {
        enable = true;
        settings = {
            
            # Sources ---------------------------------------------------------------------------------------------------------------------
            source_directories = [
                "/Storage/Services"
                "/Storage/Scripts"
            ];
            exclude_patterns = [
                "/Storage/Files/Backups/Server"
            ];
            exclude_if_present = [
                ".nobackup"
                ".stversions"
                ".thumbnails"
            ];

            # Excludes --------------------------------------------------------------------------------------------------------------------
            repositories = [
                {
                    label = "On Disk Backup"
                    path = "/Storage/Files/Backups/Server/Borgmatic"
                }
                {
                    label = "Backup Server"
                    path = "ssh://borg@10.100.100.6/Storage/Backups/Server/Borgmatic"
                }
            ];

            # Backup Settings -------------------------------------------------------------------------------------------------------------
            compression = "lz4";
            archive_name_format = "backup-{now}";
            relocated_repo_access_is_ok = true;

            # Retention -------------------------------------------------------------------------------------------------------------------
            keep_hourly = 24;
            keep_daily = 7;
            keep_weekly = 4;
            keep_monthly = 12;
            keep_yearly = 3;

            # Hooks -----------------------------------------------------------------------------------------------------------------------
            before_backup = [
                "echo Starting a backup job."
                # "ping -q -c 1 10.100.100.6 > /dev/null || exit 75"
            ];
            after_backup = [
                "echo Backup created."
            ];
            on_error = [
                "echo Error while creating a backup."
            ];

            # Consistency Checks ----------------------------------------------------------------------------------------------------------
            checks = [
                {
                    name = "repository"
                    frequency = "always"
                }
                {
                    name = "archives"
                    frequency = "always"
                }
                {
                    name = data
                    frequency = "always"
                }
                {
                    name = "extract"
                    frequency = "always"
                } 
            ];
            check_last = 3;

            # Notifications ---------------------------------------------------------------------------------------------------------------
            ntfy = {
                topic = "borgmatic";
                server = "http://ntfy"
                start = {
                    title = "Heimdall Borgmatic Backup Started";
                    message = "Updates will follow"
                    tags = [ "borgmatic" ]
                    priority = "min"
                };
                finish = {
                    title = "Heimdall Borgmatic Backup Completed";
                    message = "Nice!"
                    tags = ["borgmatic" "+1"]
                    priority = ["min"]
                };
                fail = {
                    title = "Heimdall Borgmatic Backup Failed!"
                    message = "You should probably fix it"
                    tags = [ "borgmatic" "-1" "skull" ]
                    priority = "max"
                };
                states = [
                    "start"
                    "finish"
                    "fail"
                ];
            };
        };
    };
}