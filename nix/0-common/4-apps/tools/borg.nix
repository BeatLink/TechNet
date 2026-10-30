# Borg ###############################################################################################################################################
#
# The borg CLI system-wide, because borgmatic bundles its own privately and X-Monitor's monitors need it on the system PATH.
#

{ pkgs, ... }:
{
    environment.systemPackages = with pkgs; [ borgbackup ];
}
