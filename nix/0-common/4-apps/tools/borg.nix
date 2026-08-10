# Borg ###############################################################################################################################################
#
# The borg CLI system-wide, because Vorta and borgmatic bundle their own privately and Vigil's monitors need it on the system PATH.
#

{ pkgs, ... }:
{
    environment.systemPackages = with pkgs; [ borgbackup ];
}
