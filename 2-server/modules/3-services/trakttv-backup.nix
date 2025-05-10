{
    # Enable cron service
    services.cron = {
        enable = true;
        systemCronJobs = [
            "0 0 * * * cd /Storage/Services/TraktTv-Backup/trakt-backup; ./trakt-backup.sh -u BingeWatcherSupreme"
            "0 0 1 * * cd /Storage/Services/TraktTv-Backup/trakt-backup; ./trakt-auth.sh -u BingeWatcherSupreme"
        ];
    };
}