# Time ###############################################################################################################################################
#
# The time zone shared by every host, plus the NTP client that keeps the clock honest.
#

{
    time.timeZone = "America/Jamaica";
    services.timesyncd.enable = true;
}
