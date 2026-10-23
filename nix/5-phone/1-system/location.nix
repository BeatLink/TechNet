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
{ pkgs, ... }:
{
    users.users.geoclue.extraGroups = [ "networkmanager" ];

    # The default list omits phosh, and without an agent geoclue holds every GetClient call forever, so no app ever gets a fix
    services.geoclue2.whitelistedAgents = [ "sm.puri.Phosh" ];

    # beaconDB knows no access point or cell here, so every GPS fix within 100 m sends the ones in view to it under the default nick
    services.geoclue2.submitData = true;

    # Turns the location quick setting back on at every login, so switching it off lasts until the next boot rather than silently stopping Traccar for good
    home-manager.users.beatlink.systemd.user.services.location-on = {
        Unit = {
            Description = "Switch location services on at login";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
        };
        Service = {
            Type = "oneshot";
            ExecStart = "${pkgs.dconf}/bin/dconf write /org/gnome/system/location/enabled true";
        };
        Install.WantedBy = [ "graphical-session.target" ];
    };
}
