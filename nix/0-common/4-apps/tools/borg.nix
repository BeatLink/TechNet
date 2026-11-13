# Borg ###############################################################################################################################################
#
# The borg CLI system-wide, because X-Backups' agent runs borg from the system PATH.
#

{ pkgs, ... }:
{
    environment.systemPackages = with pkgs; [ borgbackup ];
}
