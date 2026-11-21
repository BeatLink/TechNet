# Boot ###############################################################################################################################################
#
# The journal, kept on disk and synced often so the lines before an unclean shutdown survive it.
#

{ lib, ... }:
{
    config = lib.mkMerge [

        # Journal Persistence ########################################################################################################################
        {
            services.journald.settings.Journal = {
                Storage = "persistent";
                SyncIntervalSec = "5s";
            };
        }
    ];
}
