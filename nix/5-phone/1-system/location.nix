# Location
#
# geoclue2 itself is already on -- the phosh module pulls it in, and
# 1-system/6-display.nix depends on that being true for the location quick
# setting to mean anything. What is missing is the one permission it needs to
# produce a fix from anything other than the modem.
#
# geoclue's wifi source asks NetworkManager to enumerate visible access points
# and submits their BSSIDs to a positioning service. That query is privileged,
# so without membership the source silently yields nothing and location falls
# back to GPS alone -- which on this phone means waiting for the EC25 to get a
# satellite fix outdoors, rather than a rough position indoors in seconds.
#
# Recommended by the NixOS PinePhone wiki page and absent here, which is how it
# was noticed.
#
{
    users.users.geoclue.extraGroups = [ "networkmanager" ];
}
